const std = @import("std");
const config = @import("config.zig");
const constants = @import("constants.zig");
const theme = @import("theme.zig");

pub const Prepared = struct {
    argv: std.ArrayList([]const u8) = .empty,
    environment: std.ArrayList(config.Pair) = .empty,
    owned: std.ArrayList([]u8) = .empty,
    temporary_path: ?[]u8 = null,

    pub fn deinit(self: *Prepared, allocator: std.mem.Allocator, io: std.Io) void {
        self.argv.deinit(allocator);
        self.environment.deinit(allocator);
        for (self.owned.items) |value| allocator.free(value);
        self.owned.deinit(allocator);
        if (self.temporary_path) |path| {
            std.Io.Dir.cwd().deleteFile(io, path) catch {};
            allocator.free(path);
        }
    }

    fn own(self: *Prepared, allocator: std.mem.Allocator, value: []u8) ![]const u8 {
        errdefer allocator.free(value);
        try self.owned.append(allocator, value);
        return value;
    }
};

fn isPathLike(value: []const u8) bool {
    return std.Io.Dir.path.dirname(value) != null;
}

fn expandPath(allocator: std.mem.Allocator, env: *const std.process.Environ.Map, value: []const u8) ![]const u8 {
    if (std.mem.startsWith(u8, value, "~/")) {
        if (env.get(constants.environment.home)) |home| return std.Io.Dir.path.join(allocator, &.{ home, value[2..] });
    }
    return allocator.dupe(u8, value);
}

fn executable(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{ .execute = true }) catch return false;
    const stat = std.Io.Dir.cwd().statFile(io, path, .{}) catch return false;
    return stat.kind == .file;
}

fn sameFile(allocator: std.mem.Allocator, io: std.Io, left: []const u8, right: []const u8) bool {
    const left_real = std.Io.Dir.cwd().realPathFileAlloc(io, left, allocator) catch return false;
    defer allocator.free(left_real);
    const right_real = std.Io.Dir.cwd().realPathFileAlloc(io, right, allocator) catch return false;
    defer allocator.free(right_real);
    return std.mem.eql(u8, left_real, right_real);
}

fn skipped(allocator: std.mem.Allocator, io: std.Io, candidate_path: []const u8, skip_paths: []const []const u8) bool {
    for (skip_paths) |path| if (sameFile(allocator, io, candidate_path, path)) return true;
    return false;
}

fn candidate(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, raw: []const u8, skip_paths: []const []const u8) !?[]const u8 {
    var name = raw;
    if (std.mem.startsWith(u8, raw, "$")) {
        if (raw.len == 1) return null;
        name = env.get(raw[1..]) orelse return null;
        if (name.len == 0) return null;
    }
    const expanded = try expandPath(allocator, env, name);
    if (isPathLike(expanded)) {
        if (executable(io, expanded) and !skipped(allocator, io, expanded, skip_paths)) return expanded;
        allocator.free(expanded);
        return null;
    }
    defer allocator.free(expanded);
    const path = env.get(constants.environment.path) orelse constants.filesystem.default_search_path;
    var directories = std.mem.splitScalar(u8, path, std.Io.Dir.path.delimiter);
    while (directories.next()) |directory| {
        const joined = if (directory.len == 0) try allocator.dupe(u8, expanded) else try std.Io.Dir.path.join(allocator, &.{ directory, expanded });
        if (executable(io, joined) and !skipped(allocator, io, joined, skip_paths)) return joined;
        allocator.free(joined);
    }
    return null;
}

pub fn resolve(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, runner: *const config.Runner, requested: []const u8) ![]const u8 {
    if (isPathLike(requested)) return allocator.dupe(u8, requested);
    var skip_paths: std.ArrayList([]const u8) = .empty;
    defer skip_paths.deinit(allocator);
    for (runner.skip_env) |name| if (env.get(name)) |paths| {
        var it = std.mem.splitScalar(u8, paths, std.Io.Dir.path.delimiter);
        while (it.next()) |path| if (path.len != 0) try skip_paths.append(allocator, path);
    };
    const self_path = std.process.executablePathAlloc(io, allocator) catch null;
    defer if (self_path) |self| allocator.free(self);
    if (self_path) |self| try skip_paths.append(allocator, self);

    if (try candidate(allocator, io, env, requested, skip_paths.items)) |path| return path;
    const programs = if (runner.programs.len == 0) &.{runner.name} else runner.programs;
    for (programs) |program| {
        if (std.mem.eql(u8, program, requested)) continue;
        if (try candidate(allocator, io, env, program, skip_paths.items)) |path| return path;
    }
    return error.FileNotFound;
}

fn render(allocator: std.mem.Allocator, template: []const u8, theme_name: []const u8, context: []const u8) ![]u8 {
    const themed = try std.mem.replaceOwned(u8, allocator, template, constants.template.theme, theme_name);
    defer allocator.free(themed);
    return std.mem.replaceOwned(u8, allocator, themed, constants.template.context, context);
}

fn renderEnvironment(allocator: std.mem.Allocator, env: *const std.process.Environ.Map, template: []const u8, theme_name: []const u8) ![]u8 {
    const themed = try render(allocator, template, theme_name, "");
    defer allocator.free(themed);
    return std.mem.replaceOwned(u8, allocator, themed, constants.template.home, env.get(constants.environment.home) orelse "");
}

fn argumentValue(arguments: []const []const u8, flags: []const []const u8, prefixes: []const []const u8, separator: ?[]const u8) ?[]const u8 {
    var result: ?[]const u8 = null;
    var index: usize = 0;
    while (index < arguments.len) : (index += 1) {
        const arg = arguments[index];
        if (separator) |sep| if (std.mem.eql(u8, arg, sep)) break;
        for (flags) |flag| if (std.mem.eql(u8, arg, flag) and index + 1 < arguments.len) {
            index += 1;
            result = arguments[index];
        };
        for (prefixes) |prefix| {
            if (std.mem.startsWith(u8, arg, prefix) and arg.len > prefix.len) result = arg[prefix.len..];
        }
    }
    return result;
}

fn canonicalDirectory(allocator: std.mem.Allocator, io: std.Io, cwd: []const u8, value: []const u8) ![]const u8 {
    const joined = if (std.Io.Dir.path.isAbsolute(value)) null else try std.Io.Dir.path.join(allocator, &.{ cwd, value });
    defer if (joined) |path| allocator.free(path);
    const path = joined orelse value;
    var buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const length = std.Io.Dir.cwd().realPathFile(io, path, &buffer) catch return std.Io.Dir.path.resolve(allocator, &.{path});
    return allocator.dupe(u8, buffer[0..length]);
}

fn appendTomlString(output: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    try output.append(allocator, '"');
    for (value) |byte| switch (byte) {
        '\x08' => try output.appendSlice(allocator, "\\b"),
        '\t' => try output.appendSlice(allocator, "\\t"),
        '\n' => try output.appendSlice(allocator, "\\n"),
        '\r' => try output.appendSlice(allocator, "\\r"),
        '"' => try output.appendSlice(allocator, "\\\""),
        '\\' => try output.appendSlice(allocator, "\\\\"),
        else => if (byte < 0x20 or byte == 0x7f) {
            try output.appendSlice(allocator, "\\u00");
            try output.appendSlice(allocator, &std.fmt.hex(byte));
        } else try output.append(allocator, byte),
    };
    try output.append(allocator, '"');
}

fn directoryContext(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, runtime: *const config.Runtime, integration: *const config.Integration, arguments: []const []const u8) ![]const u8 {
    const cwd = try std.process.currentPathAlloc(io, allocator);
    defer allocator.free(cwd);
    const directory = try canonicalDirectory(allocator, io, cwd, argumentValue(arguments, integration.context_path_flags, integration.context_path_prefixes, integration.context_argument_separator) orelse cwd);
    var directories: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer {
        for (directories.keys()) |path| allocator.free(path);
        directories.deinit(allocator);
    }
    try directories.put(allocator, directory, {});
    for (integration.context_directory_commands) |command| {
        var argv: std.ArrayList([]const u8) = .empty;
        defer {
            for (argv.items) |arg| allocator.free(arg);
            argv.deinit(allocator);
        }
        for (command) |arg| try argv.append(allocator, try std.mem.replaceOwned(u8, allocator, arg, constants.template.directory, directory));
        const result = std.process.run(allocator, io, .{
            .argv = argv.items,
            .environ_map = env,
            .stdout_limit = .limited(runtime.helper_output_limit_bytes),
            .stderr_limit = .limited(runtime.helper_output_limit_bytes),
            .timeout = runtime.helperTimeout(),
        }) catch continue;
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);
        if (result.term != .exited or result.term.exited != 0) continue;
        const output = std.mem.trim(u8, result.stdout, constants.text.whitespace);
        if (output.len == 0 or std.mem.findScalar(u8, output, '\n') != null) continue;
        const related = canonicalDirectory(allocator, io, directory, output) catch continue;
        const related_stat = std.Io.Dir.cwd().statFile(io, related, .{}) catch {
            allocator.free(related);
            continue;
        };
        if (related_stat.kind != .directory) {
            allocator.free(related);
            continue;
        }
        const entry = try directories.getOrPut(allocator, related);
        if (entry.found_existing) allocator.free(related) else entry.value_ptr.* = {};
    }

    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try output.appendSlice(allocator, integration.context_table.?);
    try output.appendSlice(allocator, constants.text.table_open);
    for (directories.keys(), 0..) |path, index| {
        if (index != 0) try output.append(allocator, ',');
        try appendTomlString(&output, allocator, path);
        try output.appendSlice(allocator, constants.text.table_open);
        try output.appendSlice(allocator, integration.context_field.?);
        try output.append(allocator, '=');
        try appendTomlString(&output, allocator, integration.context_value.?);
        try output.append(allocator, '}');
    }
    try output.append(allocator, '}');
    return output.toOwnedSlice(allocator);
}

fn configFlag(integration: *const config.Integration, arg: []const u8) bool {
    for (integration.config_flags) |flag| if (std.mem.eql(u8, flag, arg)) return true;
    return false;
}

fn configPath(allocator: std.mem.Allocator, env: *const std.process.Environ.Map, integration: *const config.Integration, arguments: []const []const u8) ![]const u8 {
    var index: usize = 0;
    while (index < arguments.len) : (index += 1) {
        if (configFlag(integration, arguments[index]) and index + 1 < arguments.len) return expandPath(allocator, env, arguments[index + 1]);
        for (integration.config_flags) |flag| if (std.mem.startsWith(u8, arguments[index], flag) and arguments[index].len > flag.len and arguments[index][flag.len] == '=') return expandPath(allocator, env, arguments[index][flag.len + 1 ..]);
    }
    const home = env.get(constants.environment.home) orelse return allocator.dupe(u8, "");
    return std.Io.Dir.path.join(allocator, &.{ home, integration.default_config.? });
}

const AssignmentPatch = struct {
    line: ?usize = null,
    end_line: ?usize = null,
    prepend_if_missing: bool = false,
};

fn patchAssignment(allocator: std.mem.Allocator, contents: []const u8, key: []const u8, quote: u8, value: []const u8, policy: AssignmentPatch) ![]const u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    var lines = std.mem.splitScalar(u8, contents, '\n');
    var replaced = false;
    var line_number: usize = 1;
    while (lines.next()) |line| {
        defer line_number += 1;
        const trimmed = std.mem.trimStart(u8, line, constants.text.horizontal_whitespace);
        var matches = false;
        if (policy.line) |start| {
            if (line_number > start and (policy.end_line == null or line_number < policy.end_line.?)) continue;
            matches = line_number == start;
        } else if (std.mem.startsWith(u8, trimmed, key)) {
            const rest = std.mem.trimStart(u8, trimmed[key.len..], constants.text.horizontal_whitespace);
            matches = rest.len != 0 and rest[0] == '=';
        }
        if (!replaced and matches) {
            try output.appendSlice(allocator, key);
            try output.appendSlice(allocator, constants.text.assignment);
            try output.append(allocator, quote);
            try output.appendSlice(allocator, value);
            try output.append(allocator, quote);
            replaced = true;
        } else try output.appendSlice(allocator, line);
        if (lines.index != null) try output.append(allocator, '\n');
    }
    if (!replaced) {
        if (policy.prepend_if_missing) {
            var prefixed: std.ArrayList(u8) = .empty;
            errdefer prefixed.deinit(allocator);
            try prefixed.appendSlice(allocator, key);
            try prefixed.appendSlice(allocator, constants.text.assignment);
            try prefixed.append(allocator, quote);
            try prefixed.appendSlice(allocator, value);
            try prefixed.appendSlice(allocator, &.{ quote, '\n' });
            try prefixed.appendSlice(allocator, output.items);
            output.deinit(allocator);
            return prefixed.toOwnedSlice(allocator);
        }
        if (output.items.len != 0 and output.items[output.items.len - 1] != '\n') try output.append(allocator, '\n');
        try output.appendSlice(allocator, key);
        try output.appendSlice(allocator, constants.text.assignment);
        try output.append(allocator, quote);
        try output.appendSlice(allocator, value);
        try output.appendSlice(allocator, &.{ quote, '\n' });
    }
    return output.toOwnedSlice(allocator);
}

fn makeTemporary(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, integration: *const config.Integration, contents: []const u8) ![]u8 {
    const directory = switch (integration.temporary_location.?) {
        .system => try allocator.dupe(u8, env.get(constants.environment.temporary_directory) orelse constants.filesystem.default_temporary_directory),
        .cache => cache: {
            if (env.get(constants.environment.xdg_cache_home)) |base| break :cache try std.Io.Dir.path.join(allocator, &.{ base, integration.cache_subdirectory.? });
            if (env.get(constants.environment.home)) |home| break :cache try std.Io.Dir.path.join(allocator, &.{ home, constants.filesystem.default_cache_directory, integration.cache_subdirectory.? });
            break :cache try std.Io.Dir.path.join(allocator, &.{ constants.filesystem.default_temporary_directory, integration.cache_subdirectory.? });
        },
    };
    defer allocator.free(directory);
    const temporary_directory = try std.Io.Dir.cwd().createDirPathOpen(io, directory, .{});
    defer temporary_directory.close(io);
    const template = integration.temporary_prefix.?;
    const stem = template[0 .. template.len - constants.toml.temporary_suffix.len];
    while (true) {
        var random_integer: u64 = undefined;
        io.random(@ptrCast(&random_integer));
        const suffix = std.fmt.hex(random_integer);
        const basename = try std.mem.concat(allocator, u8, &.{ stem, &suffix });
        defer allocator.free(basename);
        const path = try std.Io.Dir.path.join(allocator, &.{ directory, basename });
        errdefer allocator.free(path);
        const file = temporary_directory.createFile(io, basename, .{
            .exclusive = true,
            .permissions = .fromMode(0o600),
        }) catch |err| switch (err) {
            error.PathAlreadyExists, error.FileBusy, error.DeviceBusy => {
                allocator.free(path);
                continue;
            },
            else => return err,
        };
        errdefer temporary_directory.deleteFile(io, basename) catch {};
        defer file.close(io);
        try file.writeStreamingAll(io, contents);
        return path;
    }
}

pub fn prepare(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, runtime: *const config.Runtime, integration: ?*const config.Integration, extra: []const []const u8) !Prepared {
    return prepareForTheme(allocator, io, env, runtime, integration, extra, theme.detect(allocator, io, runtime, env));
}

pub fn prepareForTheme(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, runtime: *const config.Runtime, integration: ?*const config.Integration, extra: []const []const u8, mode: config.Theme) !Prepared {
    var result: Prepared = .{};
    errdefer result.deinit(allocator, io);
    const selected = integration orelse {
        try result.argv.appendSlice(allocator, extra);
        return result;
    };
    const theme_name = if (mode == .dark) selected.dark_theme else selected.light_theme;
    switch (selected.strategy) {
        .arguments => {
            const context = if (selected.context_table != null) try directoryContext(allocator, io, env, runtime, selected, extra) else "";
            defer if (selected.context_table != null) allocator.free(context);
            for (selected.arguments) |template| try result.argv.append(allocator, try result.own(allocator, try render(allocator, template, theme_name, context)));
            try result.argv.appendSlice(allocator, extra);
        },
        .config => {
            const path = try configPath(allocator, env, selected, extra);
            defer allocator.free(path);
            const contents = std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(config.max_file_bytes)) catch |err| switch (err) {
                error.FileNotFound => try allocator.dupe(u8, ""),
                else => return err,
            };
            defer allocator.free(contents);
            var patch_policy: AssignmentPatch = .{};
            if (selected.validation == .toml) {
                const assignment = try allocator.dupeZ(u8, selected.assignment.?);
                defer allocator.free(assignment);
                const inspected = try config.inspectTomlAssignment(allocator, contents, selected.display_name, assignment);
                patch_policy = .{
                    .line = inspected.line,
                    .end_line = inspected.end_line,
                    .prepend_if_missing = inspected.kind == .missing,
                };
            }
            const patched = try patchAssignment(allocator, contents, selected.assignment.?, selected.quote.?, theme_name, patch_policy);
            defer allocator.free(patched);
            if (selected.validation == .toml) try config.validateToml(allocator, patched, selected.display_name);
            result.temporary_path = try makeTemporary(allocator, io, env, selected, patched);
            try result.argv.append(allocator, selected.config_output_flag.?);
            try result.argv.append(allocator, result.temporary_path.?);
            var index: usize = 0;
            while (index < extra.len) : (index += 1) {
                if (configFlag(selected, extra[index])) {
                    if (index + 1 < extra.len) index += 1;
                    continue;
                }
                var joined = false;
                for (selected.config_flags) |flag| {
                    if (std.mem.startsWith(u8, extra[index], flag) and extra[index].len > flag.len and extra[index][flag.len] == '=') joined = true;
                }
                if (!joined) try result.argv.append(allocator, extra[index]);
            }
        },
        .environment => {
            for (selected.env) |pair| try result.environment.append(allocator, .{
                .key = pair.key,
                .value = try result.own(allocator, try renderEnvironment(allocator, env, pair.value, theme_name)),
            });
            try result.argv.appendSlice(allocator, extra);
        },
    }
    return result;
}

fn usesInterpreter(interpreter: *const config.Interpreter, executable_path: []const u8, io: std.Io) bool {
    var buffer: [constants.filesystem.shebang_read_bytes]u8 = undefined;
    const text = std.Io.Dir.cwd().readFile(io, executable_path, &buffer) catch return false;
    const line = text[0 .. std.mem.findScalar(u8, text, '\n') orelse text.len];
    if (!std.mem.startsWith(u8, line, constants.text.shebang)) return false;
    var tokens = std.mem.tokenizeAny(u8, line[constants.text.shebang.len..], constants.text.whitespace);
    const command = tokens.next() orelse return false;
    const argument = tokens.next() orelse return false;
    return contains(interpreter.shebang_commands, command) and contains(interpreter.shebang_arguments, argument);
}

fn findInterpreter(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, interpreter: *const config.Interpreter) ![]const u8 {
    for (interpreter.programs) |program| if (try candidate(allocator, io, env, program, &.{})) |path| return path;
    return error.InterpreterNotFound;
}

pub const Invocation = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: std.ArrayList([]const u8),
    owned: std.ArrayList([]const u8),
    environment: std.process.Environ.Map,
    prepared: Prepared,

    pub fn deinit(self: *Invocation) void {
        self.environment.deinit();
        self.argv.deinit(self.allocator);
        for (self.owned.items) |value| self.allocator.free(value);
        self.owned.deinit(self.allocator);
        self.prepared.deinit(self.allocator, self.io);
    }

    pub fn replaceOrExecute(self: *Invocation, io: std.Io) !u8 {
        // Invocations that do not own a temporary file have nothing to clean up
        // after the command exits. Replace the launcher process so signals and
        // process ownership go directly to the command instead of leaving a
        // waiting wrapper that can be terminated independently of its child.
        if (self.prepared.temporary_path == null and std.process.can_replace) {
            return std.process.replace(io, .{
                .argv = self.argv.items,
                .environ_map = &self.environment,
            });
        }
        return self.execute(io);
    }

    pub fn execute(self: *Invocation, io: std.Io) !u8 {
        var child = try std.process.spawn(io, .{ .argv = self.argv.items, .environ_map = &self.environment });
        const term = try child.wait(io);
        return switch (term) {
            .exited => |status| status,
            .signal => |signal| constants.exit.signal_offset + @as(u8, @intCast(@intFromEnum(signal))),
            else => constants.exit.cannot_execute,
        };
    }
};

pub fn prepareInvocation(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, manifest: *const config.Manifest, runner: *const config.Runner, requested: []const u8, extra: []const []const u8, forced_theme: ?config.Theme) !Invocation {
    var executable_path = try resolve(allocator, io, env, runner, requested);
    var owned: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (owned.items) |value| allocator.free(value);
        owned.deinit(allocator);
    }
    owned.append(allocator, executable_path) catch |err| {
        allocator.free(executable_path);
        return err;
    };
    const integration = if (runner.integration) |name| manifest.findIntegration(name) else null;
    var prepared = if (forced_theme) |mode|
        try prepareForTheme(allocator, io, env, &manifest.runtime, integration, extra, mode)
    else
        try prepare(allocator, io, env, &manifest.runtime, integration, extra);
    errdefer prepared.deinit(allocator, io);
    var argv: std.ArrayList([]const u8) = .empty;
    errdefer argv.deinit(allocator);
    if (runner.interpreter) |name| {
        const interpreter = manifest.findInterpreter(name) orelse return error.MissingInterpreter;
        if (usesInterpreter(interpreter, executable_path, io)) {
            const script = executable_path;
            executable_path = try findInterpreter(allocator, io, env, interpreter);
            owned.append(allocator, executable_path) catch |err| {
                allocator.free(executable_path);
                return err;
            };
            try argv.append(allocator, executable_path);
            try argv.append(allocator, script);
        } else try argv.append(allocator, executable_path);
    } else try argv.append(allocator, executable_path);
    try argv.appendSlice(allocator, runner.default_args);
    try argv.appendSlice(allocator, prepared.argv.items);

    var child_env = try env.clone(allocator);
    errdefer child_env.deinit();
    for (runner.env_unset) |name| _ = child_env.swapRemove(name);
    for (runner.env) |pair| try child_env.put(pair.key, pair.value);
    for (prepared.environment.items) |pair| try child_env.put(pair.key, pair.value);
    try child_env.put(constants.environment.active, "1");
    return .{
        .allocator = allocator,
        .io = io,
        .argv = argv,
        .owned = owned,
        .environment = child_env,
        .prepared = prepared,
    };
}

pub fn runMatched(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map, manifest: *const config.Manifest, runner: *const config.Runner, requested: []const u8, extra: []const []const u8) !u8 {
    var invocation = try prepareInvocation(allocator, io, env, manifest, runner, requested, extra, null);
    defer invocation.deinit();
    return invocation.replaceOrExecute(io);
}

pub fn execUnknown(io: std.Io, argv: []const []const u8) u8 {
    return switch (std.process.replace(io, .{ .argv = argv })) {
        error.FileNotFound => constants.exit.not_found,
        else => constants.exit.cannot_execute,
    };
}

fn contains(values: []const []const u8, needle: []const u8) bool {
    for (values) |value| if (std.mem.eql(u8, value, needle)) return true;
    return false;
}

test "patches a configured assignment" {
    const patched = try patchAssignment(std.testing.allocator, "x = 1\nstyle = \"old\"\n", "style", '"', "new", .{});
    defer std.testing.allocator.free(patched);
    try std.testing.expectEqualStrings("x = 1\nstyle = \"new\"\n", patched);
}

test "template rendering owns only its result" {
    const rendered = try render(std.testing.allocator, "{theme}:{context}", "light", "workspace");
    defer std.testing.allocator.free(rendered);
    try std.testing.expectEqualStrings("light:workspace", rendered);
}

test "TOML strings use TOML control escapes" {
    var output: std.ArrayList(u8) = .empty;
    defer output.deinit(std.testing.allocator);
    try appendTomlString(&output, std.testing.allocator, "quote=\" newline=\n unit=\x1f");
    try std.testing.expectEqualStrings("\"quote=\\\" newline=\\n unit=\\u001f\"", output.items);
}

test "directory context is emitted as parser-valid TOML" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    const runtime: config.Runtime = undefined;
    const integration: config.Integration = .{
        .name = "tool",
        .strategy = .arguments,
        .display_name = "tool",
        .dark_theme = "night",
        .light_theme = "day",
        .context_table = "roots",
        .context_field = "theme",
        .context_value = "active",
    };
    const context = try directoryContext(std.testing.allocator, std.testing.io, &env, &runtime, &integration, &.{});
    defer std.testing.allocator.free(context);
    try config.validateToml(std.testing.allocator, context, "directory context");
}

test "environment integration renders theme and home placeholders" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try env.put(constants.environment.home, "/Users/tester");
    const runtime: config.Runtime = undefined;
    const integration: config.Integration = .{
        .name = "tool",
        .strategy = .environment,
        .display_name = "tool",
        .dark_theme = "night",
        .light_theme = "day",
        .env = &.{
            .{ .key = "TOOL_CONFIG", .value = "{home}/.config/tool/{theme}.toml" },
            .{ .key = "TOOL_THEME", .value = "{theme}" },
        },
    };
    var prepared = try prepareForTheme(std.testing.allocator, std.testing.io, &env, &runtime, &integration, &.{"--version"}, .light);
    defer prepared.deinit(std.testing.allocator, std.testing.io);
    try std.testing.expectEqualSlices([]const u8, &.{"--version"}, prepared.argv.items);
    try std.testing.expectEqual(2, prepared.environment.items.len);
    try std.testing.expectEqualStrings("TOOL_CONFIG", prepared.environment.items[0].key);
    try std.testing.expectEqualStrings("/Users/tester/.config/tool/day.toml", prepared.environment.items[0].value);
    try std.testing.expectEqualStrings("day", prepared.environment.items[1].value);
}

test "validated table assignment is replaced at the root" {
    const source =
        \\[appearance]
        \\dark = "night"
        \\fallback = "night"
        \\[appearance.variant]
        \\name = "dim"
        \\[view]
        \\line_numbers = "relative"
    ;
    const inspected = try config.inspectTomlAssignment(std.testing.allocator, source, "test", "appearance");
    try std.testing.expectEqual(config.TomlAssignment{ .kind = .table, .line = 1, .end_line = 6 }, inspected);
    const patched = try patchAssignment(std.testing.allocator, source, "appearance", '\'', "day", .{
        .line = inspected.line,
        .end_line = inspected.end_line,
    });
    defer std.testing.allocator.free(patched);
    try std.testing.expectEqualStrings("appearance = 'day'\n[view]\nline_numbers = \"relative\"", patched);
    try config.validateToml(std.testing.allocator, patched, "test");
}

test "missing validated assignment is prepended before tables" {
    const patched = try patchAssignment(std.testing.allocator, "[view]\nline_numbers = true\n", "appearance", '\'', "day", .{ .prepend_if_missing = true });
    defer std.testing.allocator.free(patched);
    try std.testing.expectEqualStrings("appearance = 'day'\n[view]\nline_numbers = true\n", patched);
}

test "explicit paths retain exact spelling" {
    const runner = config.Runner{ .name = "tool" };
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    const path = try resolve(std.testing.allocator, std.testing.io, &env, &runner, "./tool");
    defer std.testing.allocator.free(path);
    try std.testing.expectEqualStrings("./tool", path);
}

test "bare aliases use configured fallback while skipping wrappers" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try temporary.dir.writeFile(std.testing.io, .{
        .sub_path = "alias",
        .data = "#!/bin/sh\nexit 0\n",
        .flags = .{ .permissions = .executable_file },
    });
    try temporary.dir.writeFile(std.testing.io, .{
        .sub_path = "target",
        .data = "#!/bin/sh\nexit 0\n",
        .flags = .{ .permissions = .executable_file },
    });
    var buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const length = try temporary.dir.realPath(std.testing.io, &buffer);

    const wrapper = try std.Io.Dir.path.join(std.testing.allocator, &.{ buffer[0..length], "alias" });
    defer std.testing.allocator.free(wrapper);
    const expected = try std.Io.Dir.path.join(std.testing.allocator, &.{ buffer[0..length], "target" });
    defer std.testing.allocator.free(expected);
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try env.put(constants.environment.path, buffer[0..length]);
    try env.put("TEST_WRAPPER", wrapper);
    const runner: config.Runner = .{
        .name = "target",
        .aliases = &.{"alias"},
        .programs = &.{ "alias", "target" },
        .skip_env = &.{"TEST_WRAPPER"},
    };
    const resolved = try resolve(std.testing.allocator, std.testing.io, &env, &runner, "alias");
    defer std.testing.allocator.free(resolved);
    try std.testing.expectEqualStrings(expected, resolved);
}

test "invocation deinit releases resolved executable ownership" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    const runner: config.Runner = .{ .name = "sh" };
    var manifest = config.Manifest.init(std.testing.allocator, undefined);
    defer manifest.deinit();
    var invocation = try prepareInvocation(std.testing.allocator, std.testing.io, &env, &manifest, &runner, "/bin/sh", &.{ "-c", "exit 0" }, .dark);
    defer invocation.deinit();
    try std.testing.expectEqualStrings("/bin/sh", invocation.argv.items[0]);
}

test "prepared config cleanup removes its private file" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    var path_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const path_length = try temporary.dir.realPath(std.testing.io, &path_buffer);
    const cache_path = path_buffer[0..path_length];

    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try env.put(constants.environment.xdg_cache_home, cache_path);
    try env.put("TEST_THEME", @tagName(config.Theme.dark));
    const runtime: config.Runtime = .{
        .theme_environment = &.{"TEST_THEME"},
        .theme_dark_aliases = &.{},
        .theme_light_aliases = &.{},
        .theme_macos_commands = &.{},
        .theme_unix_commands = &.{},
        .theme_terminal_program_environment = "TEST_TERMINAL",
        .theme_terminal_queries = &.{.{ .key = constants.protocol.wildcard, .value = .background }},
        .theme_macos_fallback = .dark,
        .theme_unix_fallback = .dark,
        .theme_probe_timeout_ms = 1,
        .helper_timeout_ms = 1,
        .helper_output_limit_bytes = 128,
    };
    const integration: config.Integration = .{
        .name = "tool",
        .strategy = .config,
        .display_name = "tool",
        .dark_theme = "night",
        .light_theme = "day",
        .default_config = ".config/tool/config.toml",
        .assignment = "style",
        .config_flags = &.{ "--config", "-c" },
        .config_output_flag = "--config",
        .temporary_prefix = "tool-XXXXXX",
        .temporary_location = .cache,
        .cache_subdirectory = "tool",
        .quote = '"',
    };
    var prepared = try prepare(std.testing.allocator, std.testing.io, &env, &runtime, &integration, &.{ "--config", "/does/not/exist" });
    const temporary_path = try std.testing.allocator.dupe(u8, prepared.temporary_path.?);
    defer std.testing.allocator.free(temporary_path);
    try std.Io.Dir.cwd().access(std.testing.io, temporary_path, .{});
    prepared.deinit(std.testing.allocator, std.testing.io);
    try std.testing.expectError(error.FileNotFound, std.Io.Dir.cwd().access(std.testing.io, temporary_path, .{}));
}
