const std = @import("std");
const embedded = @import("embedded_data");
const c = @import("c");
const constants = @import("constants.zig");

pub const max_file_bytes = constants.filesystem.max_file_bytes;

pub const Pair = struct { key: []const u8, value: []const u8 };
pub const Command = []const []const u8;
pub const IntegrationStrategy = enum { arguments, config, environment };
pub const TemporaryLocation = enum { system, cache };
pub const TerminalProtocol = enum { background, @"color-scheme" };
pub const Validation = enum { toml };

pub const TerminalQuery = struct { key: []const u8, value: TerminalProtocol };

const RootSection = enum { runtime, interpreter, runner, integration };

pub const Runner = struct {
    name: []const u8,
    aliases: []const []const u8 = &.{},
    programs: []const []const u8 = &.{},
    skip_env: []const []const u8 = &.{},
    default_args: []const []const u8 = &.{},
    env: []const Pair = &.{},
    env_unset: []const []const u8 = &.{},
    integration: ?[]const u8 = null,
    interpreter: ?[]const u8 = null,
};

pub const Interpreter = struct {
    name: []const u8,
    shebang_commands: []const []const u8,
    shebang_arguments: []const []const u8,
    programs: []const []const u8,
};

pub const Integration = struct {
    name: []const u8,
    strategy: IntegrationStrategy,
    display_name: []const u8,
    dark_theme: []const u8,
    light_theme: []const u8,
    arguments: []const []const u8 = &.{},
    env: []const Pair = &.{},
    context_table: ?[]const u8 = null,
    context_field: ?[]const u8 = null,
    context_value: ?[]const u8 = null,
    context_path_flags: []const []const u8 = &.{},
    context_path_prefixes: []const []const u8 = &.{},
    context_argument_separator: ?[]const u8 = null,
    context_directory_commands: []const Command = &.{},
    default_config: ?[]const u8 = null,
    assignment: ?[]const u8 = null,
    config_flags: []const []const u8 = &.{},
    config_output_flag: ?[]const u8 = null,
    temporary_prefix: ?[]const u8 = null,
    temporary_location: ?TemporaryLocation = null,
    cache_subdirectory: ?[]const u8 = null,
    quote: ?u8 = null,
    validation: ?Validation = null,
};

pub const Runtime = struct {
    theme_environment: []const []const u8,
    theme_dark_aliases: []const []const u8,
    theme_light_aliases: []const []const u8,
    theme_macos_commands: []const Command,
    theme_unix_commands: []const Command,
    theme_terminal_program_environment: []const u8,
    theme_terminal_queries: []const TerminalQuery,
    theme_macos_fallback: Theme,
    theme_unix_fallback: Theme,
    theme_probe_timeout_ms: u32,
    helper_timeout_ms: u32,
    helper_output_limit_bytes: usize,

    pub fn terminalTimeout(self: *const Runtime) std.Io.Timeout {
        return awakeTimeout(self.theme_probe_timeout_ms);
    }

    pub fn helperTimeout(self: *const Runtime) std.Io.Timeout {
        return awakeTimeout(self.helper_timeout_ms);
    }
};

pub const Theme = enum { dark, light };

const RunnerField = std.meta.FieldEnum(Runner);
const InterpreterField = std.meta.FieldEnum(Interpreter);
const IntegrationField = std.meta.FieldEnum(Integration);
const RuntimeField = std.meta.FieldEnum(Runtime);

fn awakeTimeout(milliseconds: u32) std.Io.Timeout {
    return .{ .duration = .{ .raw = .fromMilliseconds(milliseconds), .clock = .awake } };
}

fn fieldName(comptime field: anytype) [*:0]const u8 {
    return @tagName(field);
}

pub const Manifest = struct {
    arena: std.heap.ArenaAllocator,
    runners: std.StringArrayHashMapUnmanaged(Runner) = .empty,
    integrations: std.StringArrayHashMapUnmanaged(Integration) = .empty,
    interpreters: std.StringArrayHashMapUnmanaged(Interpreter) = .empty,
    runner_aliases: std.StringHashMapUnmanaged(usize) = .empty,
    runtime: Runtime,

    pub fn init(allocator: std.mem.Allocator, runtime: Runtime) Manifest {
        return .{ .arena = .init(allocator), .runtime = runtime };
    }

    fn ownedAllocator(self: *Manifest) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn deinit(self: *Manifest) void {
        const allocator = self.ownedAllocator();
        self.runners.deinit(allocator);
        self.integrations.deinit(allocator);
        self.interpreters.deinit(allocator);
        self.runner_aliases.deinit(allocator);
        self.arena.deinit();
    }

    pub fn findRunner(self: *const Manifest, command: []const u8) ?*const Runner {
        const index = self.findRunnerIndex(command) orelse return null;
        return &self.runners.values()[index];
    }

    pub fn findRunnerIndex(self: *const Manifest, command: []const u8) ?usize {
        const base = std.Io.Dir.path.basename(command);
        return self.runners.getIndex(base) orelse self.runner_aliases.get(base);
    }

    pub fn findIntegration(self: *const Manifest, name: []const u8) ?*const Integration {
        return self.integrations.getPtr(name);
    }

    pub fn findInterpreter(self: *const Manifest, name: []const u8) ?*const Interpreter {
        return self.interpreters.getPtr(name);
    }

    pub fn load(allocator: std.mem.Allocator, io: std.Io, env: *const std.process.Environ.Map) !Manifest {
        var manifest = Manifest.init(allocator, undefined);
        errdefer manifest.deinit();

        try manifest.loadFragment(embedded.manifest, "embedded defaults.toml", true);

        if (env.get(constants.environment.config)) |paths| {
            var it = std.mem.splitScalar(u8, paths, std.Io.Dir.path.delimiter);
            while (it.next()) |path| if (path.len != 0) try manifest.loadOptionalFragment(io, path, true);
        } else if (env.get(constants.environment.xdg_config_home)) |xdg| {
            const owned = manifest.ownedAllocator();
            const path = try std.Io.Dir.path.join(owned, &.{ xdg, constants.filesystem.config_directory, constants.filesystem.config_file });
            defer owned.free(path);
            try manifest.loadOptionalFragment(io, path, true);
        } else if (env.get(constants.environment.home)) |home| {
            const owned = manifest.ownedAllocator();
            const path = try std.Io.Dir.path.join(owned, &.{ home, constants.filesystem.default_path });
            defer owned.free(path);
            try manifest.loadOptionalFragment(io, path, true);
        }

        try manifest.validate();
        return manifest;
    }

    pub fn loadText(allocator: std.mem.Allocator, override: ?[]const u8) !Manifest {
        var manifest = Manifest.init(allocator, undefined);
        errdefer manifest.deinit();
        try manifest.loadFragment(embedded.manifest, "embedded defaults.toml", true);
        if (override) |contents| {
            if (contents.len != 0) try manifest.loadFragment(contents, "C API manifest", true);
        }
        try manifest.validate();
        return manifest;
    }

    fn loadOptionalFragment(self: *Manifest, io: std.Io, path: []const u8, comptime allow_runtime: bool) !void {
        const allocator = self.ownedAllocator();
        const contents = readFile(allocator, io, path) catch |err| switch (err) {
            error.FileNotFound => return,
            else => return err,
        };
        defer allocator.free(contents);
        try self.loadFragment(contents, path, allow_runtime);
    }

    fn loadFragment(self: *Manifest, contents: []const u8, source: []const u8, comptime allow_runtime: bool) !void {
        const allocator = self.ownedAllocator();
        var doc = try Document.parse(allocator, contents, source);
        defer doc.deinit();
        try rejectUnknown(doc.root(), RootSection);

        const runtime = get(doc.root(), fieldName(RootSection.runtime));
        if (runtime.type != c.TOML_UNKNOWN) {
            if (!allow_runtime) return error.RuntimeOverrideNotAllowed;
            self.runtime = try parseRuntimeTable(allocator, runtime);
        }

        const interpreters = get(doc.root(), fieldName(RootSection.interpreter));
        if (interpreters.type != c.TOML_UNKNOWN) {
            if (interpreters.type != c.TOML_ARRAY) return error.InterpreterMustBeArray;
            var index: usize = 0;
            while (index < arrayLength(interpreters)) : (index += 1) {
                try putInterpreter(self, try parseInterpreter(allocator, interpreters.u.arr.elem[index]));
            }
        }

        const runners = get(doc.root(), fieldName(RootSection.runner));
        if (runners.type != c.TOML_UNKNOWN) {
            if (runners.type != c.TOML_ARRAY) return error.RunnerMustBeArray;
            var index: usize = 0;
            while (index < arrayLength(runners)) : (index += 1) {
                const runner = try parseRunner(allocator, runners.u.arr.elem[index]);
                try putRunner(self, runner);
            }
        }
        const integrations = get(doc.root(), fieldName(RootSection.integration));
        if (integrations.type != c.TOML_UNKNOWN) {
            if (integrations.type != c.TOML_ARRAY) return error.IntegrationMustBeArray;
            var index: usize = 0;
            while (index < arrayLength(integrations)) : (index += 1) {
                const integration = try parseIntegration(allocator, integrations.u.arr.elem[index]);
                try putIntegration(self, integration);
            }
        }
    }

    fn validate(self: *Manifest) !void {
        const allocator = self.ownedAllocator();
        self.runner_aliases.clearRetainingCapacity();
        for (self.runners.values(), 0..) |runner, i| {
            if (runner.name.len == 0) return error.EmptyRunnerName;
            for (runner.aliases) |alias| {
                if (alias.len == 0) return error.EmptyAlias;
                if (self.runners.contains(alias)) return error.AliasCollision;
                const entry = try self.runner_aliases.getOrPut(allocator, alias);
                if (entry.found_existing) return error.AliasCollision;
                entry.value_ptr.* = i;
            }
            if (runner.integration) |name| if (self.findIntegration(name) == null) return error.MissingIntegration;
            if (runner.interpreter) |name| if (self.findInterpreter(name) == null) return error.MissingInterpreter;
        }
    }
};

fn putRunner(manifest: *Manifest, value: Runner) !void {
    try manifest.runners.put(manifest.ownedAllocator(), value.name, value);
}

fn putIntegration(manifest: *Manifest, value: Integration) !void {
    try manifest.integrations.put(manifest.ownedAllocator(), value.name, value);
}

fn putInterpreter(manifest: *Manifest, value: Interpreter) !void {
    try manifest.interpreters.put(manifest.ownedAllocator(), value.name, value);
}

const Document = struct {
    result: c.toml_result_t,
    allocator: std.mem.Allocator,
    text: [:0]u8,
    source: [:0]u8,

    fn parse(allocator: std.mem.Allocator, contents: []const u8, source: []const u8) !Document {
        if (contents.len > std.math.maxInt(c_int)) return error.FileTooBig;
        const text = try allocator.dupeZ(u8, contents);
        errdefer allocator.free(text);
        const source_z = try allocator.dupeZ(u8, source);
        errdefer allocator.free(source_z);
        const result = c.toml_parse_named(text.ptr, @intCast(contents.len), source_z.ptr);
        if (!result.ok) return error.InvalidToml;
        return .{ .result = result, .allocator = allocator, .text = text, .source = source_z };
    }

    fn deinit(self: *Document) void {
        c.toml_free(self.result);
        self.allocator.free(self.text);
        self.allocator.free(self.source);
    }

    fn root(self: *const Document) c.toml_datum_t {
        return self.result.toptab;
    }
};

fn get(table: c.toml_datum_t, key: [*:0]const u8) c.toml_datum_t {
    return c.toml_get(table, key);
}

fn arrayLength(value: c.toml_datum_t) usize {
    return if (value.u.arr.size < 0) 0 else @intCast(value.u.arr.size);
}

fn rejectUnknown(table: c.toml_datum_t, comptime Schema: type) !void {
    if (table.type != c.TOML_TABLE) return error.ExpectedTable;
    const Field = switch (@typeInfo(Schema)) {
        .@"enum" => Schema,
        .@"struct" => std.meta.FieldEnum(Schema),
        else => @compileError("TOML schemas must be structs or enums"),
    };
    var i: usize = 0;
    while (i < @as(usize, @intCast(table.u.tab.size))) : (i += 1) {
        const key = std.mem.span(table.u.tab.key[i]);
        if (std.meta.stringToEnum(Field, key) == null) return error.UnknownField;
    }
}

fn requiredString(allocator: std.mem.Allocator, table: c.toml_datum_t, key: [*:0]const u8) ![]const u8 {
    const value = get(table, key);
    if (value.type != c.TOML_STRING) return error.RequiredString;
    return allocator.dupe(u8, std.mem.span(value.u.s));
}

fn optionalString(allocator: std.mem.Allocator, table: c.toml_datum_t, key: [*:0]const u8) !?[]const u8 {
    const value = get(table, key);
    if (value.type == c.TOML_UNKNOWN) return null;
    if (value.type != c.TOML_STRING) return error.ExpectedString;
    const copy: []const u8 = try allocator.dupe(u8, std.mem.span(value.u.s));
    return copy;
}

fn stringArray(allocator: std.mem.Allocator, table: c.toml_datum_t, key: [*:0]const u8, required: bool) ![]const []const u8 {
    const value = get(table, key);
    if (value.type == c.TOML_UNKNOWN and !required) return &.{};
    if (value.type != c.TOML_ARRAY) return error.ExpectedStringArray;
    const result = try allocator.alloc([]const u8, arrayLength(value));
    for (result, 0..) |*slot, i| {
        const item = value.u.arr.elem[i];
        if (item.type != c.TOML_STRING) return error.ExpectedStringArray;
        slot.* = try allocator.dupe(u8, std.mem.span(item.u.s));
    }
    return result;
}

fn commandArray(allocator: std.mem.Allocator, table: c.toml_datum_t, key: [*:0]const u8, required: bool) ![]const Command {
    const value = get(table, key);
    if (value.type == c.TOML_UNKNOWN and !required) return &.{};
    if (value.type != c.TOML_ARRAY) return error.ExpectedCommandArray;
    const result = try allocator.alloc(Command, arrayLength(value));
    for (result, 0..) |*command, i| {
        const item = value.u.arr.elem[i];
        if (item.type != c.TOML_ARRAY or arrayLength(item) == 0) return error.ExpectedCommandArray;
        const argv = try allocator.alloc([]const u8, arrayLength(item));
        for (argv, 0..) |*arg, j| {
            const element = item.u.arr.elem[j];
            if (element.type != c.TOML_STRING or std.mem.span(element.u.s).len == 0) return error.ExpectedCommandArray;
            arg.* = try allocator.dupe(u8, std.mem.span(element.u.s));
        }
        command.* = argv;
    }
    return result;
}

fn stringMap(allocator: std.mem.Allocator, table: c.toml_datum_t, key: [*:0]const u8) ![]const Pair {
    const value = get(table, key);
    if (value.type == c.TOML_UNKNOWN) return &.{};
    if (value.type != c.TOML_TABLE) return error.ExpectedStringMap;
    const result = try allocator.alloc(Pair, @intCast(value.u.tab.size));
    for (result, 0..) |*pair, i| {
        const item = value.u.tab.value[i];
        if (item.type != c.TOML_STRING) return error.ExpectedStringMap;
        pair.* = .{
            .key = try allocator.dupe(u8, std.mem.span(value.u.tab.key[i])),
            .value = try allocator.dupe(u8, std.mem.span(item.u.s)),
        };
    }
    return result;
}

fn terminalQueries(allocator: std.mem.Allocator, table: c.toml_datum_t, key: [*:0]const u8) ![]const TerminalQuery {
    const value = get(table, key);
    if (value.type != c.TOML_TABLE) return error.ExpectedStringMap;
    const result = try allocator.alloc(TerminalQuery, @intCast(value.u.tab.size));
    for (result, 0..) |*query, i| {
        const item = value.u.tab.value[i];
        if (item.type != c.TOML_STRING) return error.ExpectedStringMap;
        query.* = .{
            .key = try allocator.dupe(u8, std.mem.span(value.u.tab.key[i])),
            .value = std.meta.stringToEnum(TerminalProtocol, std.mem.span(item.u.s)) orelse return error.InvalidTerminalProtocol,
        };
    }
    return result;
}

fn environment(allocator: std.mem.Allocator, table: c.toml_datum_t, comptime field: anytype) ![]const Pair {
    const key = fieldName(field);
    const value = get(table, key);
    if (value.type == c.TOML_UNKNOWN) return &.{};
    if (value.type == c.TOML_TABLE) return stringMap(allocator, table, key);
    if (value.type != c.TOML_ARRAY) return error.ExpectedEnvironment;
    const result = try allocator.alloc(Pair, arrayLength(value));
    for (result, 0..) |*pair, i| {
        const item = value.u.arr.elem[i];
        if (item.type != c.TOML_STRING) return error.ExpectedEnvironment;
        const assignment = std.mem.span(item.u.s);
        const equal = std.mem.findScalar(u8, assignment, '=') orelse return error.ExpectedEnvironment;
        if (equal == 0) return error.ExpectedEnvironment;
        pair.* = .{ .key = try allocator.dupe(u8, assignment[0..equal]), .value = try allocator.dupe(u8, assignment[equal + 1 ..]) };
    }
    return result;
}

fn validateEnvName(name: []const u8) !void {
    if (!std.process.Environ.Map.validateKeyForPut(name)) return error.InvalidEnvironmentName;
}

fn parseRunner(allocator: std.mem.Allocator, table: c.toml_datum_t) !Runner {
    try rejectUnknown(table, Runner);
    const runner: Runner = .{
        .name = try requiredString(allocator, table, fieldName(RunnerField.name)),
        .aliases = try stringArray(allocator, table, fieldName(RunnerField.aliases), false),
        .programs = try stringArray(allocator, table, fieldName(RunnerField.programs), false),
        .skip_env = try stringArray(allocator, table, fieldName(RunnerField.skip_env), false),
        .default_args = try stringArray(allocator, table, fieldName(RunnerField.default_args), false),
        .env = try environment(allocator, table, RunnerField.env),
        .env_unset = try stringArray(allocator, table, fieldName(RunnerField.env_unset), false),
        .integration = try optionalString(allocator, table, fieldName(RunnerField.integration)),
        .interpreter = try optionalString(allocator, table, fieldName(RunnerField.interpreter)),
    };
    for (runner.skip_env) |name| try validateEnvName(name);
    for (runner.env_unset) |name| try validateEnvName(name);
    for (runner.env) |pair| try validateEnvName(pair.key);
    for (runner.programs) |program| if (std.mem.eql(u8, program, "$")) return error.InvalidProgramReference;
    return runner;
}

fn parseInterpreter(allocator: std.mem.Allocator, table: c.toml_datum_t) !Interpreter {
    try rejectUnknown(table, Interpreter);
    const result: Interpreter = .{
        .name = try requiredString(allocator, table, fieldName(InterpreterField.name)),
        .shebang_commands = try stringArray(allocator, table, fieldName(InterpreterField.shebang_commands), true),
        .shebang_arguments = try stringArray(allocator, table, fieldName(InterpreterField.shebang_arguments), true),
        .programs = try stringArray(allocator, table, fieldName(InterpreterField.programs), true),
    };
    if (result.name.len == 0 or result.shebang_commands.len == 0 or result.shebang_arguments.len == 0 or result.programs.len == 0) return error.InvalidInterpreter;
    return result;
}

fn parseIntegration(allocator: std.mem.Allocator, table: c.toml_datum_t) !Integration {
    try rejectUnknown(table, Integration);
    const name = try requiredString(allocator, table, fieldName(IntegrationField.name));
    const strategy = try requiredEnum(IntegrationStrategy, table, fieldName(IntegrationField.strategy), error.UnsupportedStrategy);
    const display_name = (try optionalString(allocator, table, fieldName(IntegrationField.display_name))) orelse name;
    const quote_text = try optionalString(allocator, table, fieldName(IntegrationField.quote));
    var result: Integration = .{
        .name = name,
        .strategy = strategy,
        .display_name = display_name,
        .dark_theme = try requiredString(allocator, table, fieldName(IntegrationField.dark_theme)),
        .light_theme = try requiredString(allocator, table, fieldName(IntegrationField.light_theme)),
        .arguments = try stringArray(allocator, table, fieldName(IntegrationField.arguments), false),
        .env = try environment(allocator, table, IntegrationField.env),
        .context_table = try optionalString(allocator, table, fieldName(IntegrationField.context_table)),
        .context_field = try optionalString(allocator, table, fieldName(IntegrationField.context_field)),
        .context_value = try optionalString(allocator, table, fieldName(IntegrationField.context_value)),
        .context_path_flags = try stringArray(allocator, table, fieldName(IntegrationField.context_path_flags), false),
        .context_path_prefixes = try stringArray(allocator, table, fieldName(IntegrationField.context_path_prefixes), false),
        .context_argument_separator = try optionalString(allocator, table, fieldName(IntegrationField.context_argument_separator)),
        .context_directory_commands = try commandArray(allocator, table, fieldName(IntegrationField.context_directory_commands), false),
        .default_config = try optionalString(allocator, table, fieldName(IntegrationField.default_config)),
        .assignment = try optionalString(allocator, table, fieldName(IntegrationField.assignment)),
        .config_flags = try stringArray(allocator, table, fieldName(IntegrationField.config_flags), false),
        .config_output_flag = try optionalString(allocator, table, fieldName(IntegrationField.config_output_flag)),
        .temporary_prefix = try optionalString(allocator, table, fieldName(IntegrationField.temporary_prefix)),
        .temporary_location = try optionalEnum(TemporaryLocation, table, fieldName(IntegrationField.temporary_location), error.InvalidTemporaryLocation),
        .cache_subdirectory = try optionalString(allocator, table, fieldName(IntegrationField.cache_subdirectory)),
        .validation = try optionalEnum(Validation, table, fieldName(IntegrationField.validation), error.InvalidValidation),
    };
    if (quote_text) |quote| {
        if (quote.len != 1 or (quote[0] != '\'' and quote[0] != '"')) return error.InvalidQuote;
        result.quote = quote[0];
    }
    for (result.env) |pair| try validateEnvName(pair.key);
    try validateIntegration(result);
    return result;
}

fn hasPlaceholder(values: []const []const u8, placeholder: []const u8) bool {
    for (values) |value| if (std.mem.find(u8, value, placeholder) != null) return true;
    return false;
}

fn validateIntegration(value: Integration) !void {
    if (value.name.len == 0 or value.dark_theme.len == 0 or value.light_theme.len == 0) return error.EmptyIntegrationField;
    switch (value.strategy) {
        .arguments => {
            if (value.arguments.len == 0 or !hasPlaceholder(value.arguments, constants.template.theme)) return error.InvalidArgumentIntegration;
            const context_count = @as(u8, @intFromBool(value.context_table != null)) + @as(u8, @intFromBool(value.context_field != null)) + @as(u8, @intFromBool(value.context_value != null));
            if (context_count != 0 and context_count != 3) return error.InvalidContextPolicy;
            if (context_count == 3 and !hasPlaceholder(value.arguments, constants.template.context)) return error.InvalidContextPolicy;
            for (value.context_directory_commands) |command| {
                var found = false;
                for (command) |arg| {
                    if (std.mem.find(u8, arg, constants.template.directory) != null) found = true;
                }
                if (!found) return error.InvalidContextCommand;
            }
        },
        .config => {
            if (value.default_config == null or value.assignment == null or value.config_flags.len == 0 or value.config_output_flag == null or value.temporary_prefix == null or value.temporary_location == null or value.quote == null) return error.InvalidConfigIntegration;
            if (!std.mem.endsWith(u8, value.temporary_prefix.?, constants.toml.temporary_suffix) or std.Io.Dir.path.basename(value.temporary_prefix.?).len != value.temporary_prefix.?.len) return error.InvalidTemporaryPrefix;
            if (value.temporary_location.? == .cache and value.cache_subdirectory == null) return error.InvalidConfigIntegration;
        },
        .environment => {
            if (value.env.len == 0) return error.InvalidEnvironmentIntegration;
            var has_theme = false;
            for (value.env) |pair| if (std.mem.find(u8, pair.value, constants.template.theme) != null) {
                has_theme = true;
            };
            if (!has_theme) return error.InvalidEnvironmentIntegration;
        },
    }
}

fn requiredEnum(comptime E: type, table: c.toml_datum_t, key: [*:0]const u8, invalid: anyerror) !E {
    const value = get(table, key);
    if (value.type != c.TOML_STRING) return error.RequiredString;
    return std.meta.stringToEnum(E, std.mem.span(value.u.s)) orelse invalid;
}

fn optionalEnum(comptime E: type, table: c.toml_datum_t, key: [*:0]const u8, invalid: anyerror) !?E {
    const value = get(table, key);
    if (value.type == c.TOML_UNKNOWN) return null;
    if (value.type != c.TOML_STRING) return error.ExpectedString;
    return std.meta.stringToEnum(E, std.mem.span(value.u.s)) orelse invalid;
}

fn requiredInt(table: c.toml_datum_t, key: [*:0]const u8, maximum: u64) !u64 {
    const value = get(table, key);
    if (value.type != c.TOML_INT64 or value.u.int64 <= 0 or value.u.int64 > maximum) return error.InvalidRuntimeLimit;
    return @intCast(value.u.int64);
}

fn parseRuntimeTable(allocator: std.mem.Allocator, table: c.toml_datum_t) !Runtime {
    try rejectUnknown(table, Runtime);
    return parseRuntimeFields(allocator, table);
}

fn parseRuntimeFields(allocator: std.mem.Allocator, table: c.toml_datum_t) !Runtime {
    const result: Runtime = .{
        .theme_environment = try stringArray(allocator, table, fieldName(RuntimeField.theme_environment), true),
        .theme_dark_aliases = try stringArray(allocator, table, fieldName(RuntimeField.theme_dark_aliases), true),
        .theme_light_aliases = try stringArray(allocator, table, fieldName(RuntimeField.theme_light_aliases), true),
        .theme_macos_commands = try commandArray(allocator, table, fieldName(RuntimeField.theme_macos_commands), true),
        .theme_unix_commands = try commandArray(allocator, table, fieldName(RuntimeField.theme_unix_commands), true),
        .theme_terminal_program_environment = try requiredString(allocator, table, fieldName(RuntimeField.theme_terminal_program_environment)),
        .theme_terminal_queries = try terminalQueries(allocator, table, fieldName(RuntimeField.theme_terminal_queries)),
        .theme_macos_fallback = try requiredEnum(Theme, table, fieldName(RuntimeField.theme_macos_fallback), error.InvalidTheme),
        .theme_unix_fallback = try requiredEnum(Theme, table, fieldName(RuntimeField.theme_unix_fallback), error.InvalidTheme),
        .theme_probe_timeout_ms = @intCast(try requiredInt(table, fieldName(RuntimeField.theme_probe_timeout_ms), constants.toml.runtime_limit_maximum)),
        .helper_timeout_ms = @intCast(try requiredInt(table, fieldName(RuntimeField.helper_timeout_ms), constants.toml.runtime_limit_maximum)),
        .helper_output_limit_bytes = @intCast(try requiredInt(table, fieldName(RuntimeField.helper_output_limit_bytes), max_file_bytes)),
    };
    if (result.theme_environment.len == 0) return error.InvalidRuntime;
    var has_fallback = false;
    for (result.theme_terminal_queries) |pair| {
        if (std.mem.eql(u8, pair.key, constants.protocol.wildcard)) has_fallback = true;
    }
    if (!has_fallback) return error.MissingTerminalFallback;
    return result;
}

fn readFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ![]u8 {
    return std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(max_file_bytes));
}

pub fn validateToml(allocator: std.mem.Allocator, contents: []const u8, source: []const u8) !void {
    var document = try Document.parse(allocator, contents, source);
    document.deinit();
}

pub const TomlAssignment = struct {
    kind: enum { missing, string, table },
    line: ?usize,
    end_line: ?usize,
};

fn nextRootLine(root: c.toml_datum_t, line: usize) ?usize {
    var result: ?usize = null;
    var index: usize = 0;
    while (index < @as(usize, @intCast(root.u.tab.size))) : (index += 1) {
        const candidate = root.u.tab.value[index].lineno;
        if (candidate <= line) continue;
        const candidate_line: usize = @intCast(candidate);
        if (result == null or candidate_line < result.?) result = candidate_line;
    }
    return result;
}

pub fn inspectTomlAssignment(allocator: std.mem.Allocator, contents: []const u8, source: []const u8, key: [:0]const u8) !TomlAssignment {
    var document = try Document.parse(allocator, contents, source);
    defer document.deinit();
    const root = document.root();
    const value = get(root, key.ptr);
    const line: ?usize = if (value.lineno > 0) @intCast(value.lineno) else null;
    return switch (value.type) {
        c.TOML_UNKNOWN => .{ .kind = .missing, .line = null, .end_line = null },
        c.TOML_STRING => .{ .kind = .string, .line = line, .end_line = null },
        c.TOML_TABLE => .{ .kind = .table, .line = line, .end_line = if (line) |start| nextRootLine(root, start) else null },
        else => error.AssignmentMustBeString,
    };
}

test "nested command arrays reject shell strings" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const bad =
        \\[runtime]
        \\theme_macos_commands = ["single shell string"]
        \\theme_environment=["THEME"]
        \\theme_dark_aliases=[]
        \\theme_light_aliases=[]
        \\theme_unix_commands=[]
        \\theme_terminal_program_environment="TERM_PROGRAM"
        \\theme_terminal_queries={"*"="background"}
        \\theme_macos_fallback="dark"
        \\theme_unix_fallback="dark"
        \\theme_probe_timeout_ms=1
        \\helper_timeout_ms=1
        \\helper_output_limit_bytes=1
    ;
    var document = try Document.parse(arena.allocator(), bad, "test");
    defer document.deinit();
    try std.testing.expectError(error.ExpectedCommandArray, parseRuntimeTable(arena.allocator(), get(document.root(), fieldName(RootSection.runtime))));
}

test "reflected schemas reject unknown fields" {
    try std.testing.expectError(error.UnknownField, Manifest.loadText(std.testing.allocator,
        \\[[runner]]
        \\name = "tool"
        \\hand_written_schema_key = true
    ));
}

test "manifest owns parser allocations" {
    var manifest = try Manifest.loadText(std.testing.allocator, null);
    defer manifest.deinit();
    try std.testing.expect(manifest.runtime.theme_environment.len != 0);
}

test "runner aliases are globally unique" {
    const runtime: Runtime = undefined;
    var manifest = Manifest.init(std.testing.allocator, runtime);
    defer manifest.deinit();
    const allocator = manifest.ownedAllocator();
    try manifest.runners.put(allocator, "primary", .{ .name = "primary", .aliases = &.{"alias"} });
    try manifest.runners.put(allocator, "alias", .{ .name = "alias" });
    try std.testing.expectError(error.AliasCollision, manifest.validate());
}

fn temporaryPath(allocator: std.mem.Allocator, temporary: *std.testing.TmpDir, relative: []const u8) ![]const u8 {
    var buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const length = try temporary.dir.realPath(std.testing.io, &buffer);
    return std.Io.Dir.path.join(allocator, &.{ buffer[0..length], relative });
}

test "explicit configuration paths merge in order" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try temporary.dir.writeFile(std.testing.io, .{
        .sub_path = "first.toml",
        .data = "[[runner]]\nname = \"tool\"\naliases = [\"first-alias\"]\nprograms = [\"first\"]\n",
    });
    try temporary.dir.writeFile(std.testing.io, .{
        .sub_path = "second.toml",
        .data = "[[runner]]\nname = \"tool\"\naliases = [\"last-alias\"]\nprograms = [\"last\"]\n",
    });

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const first = try temporaryPath(arena.allocator(), &temporary, "first.toml");
    const second = try temporaryPath(arena.allocator(), &temporary, "second.toml");
    const delimiter = [_]u8{std.Io.Dir.path.delimiter};
    const paths = try std.mem.join(arena.allocator(), &delimiter, &.{ first, second });
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try env.put(constants.environment.config, paths);
    var manifest = try Manifest.load(std.testing.allocator, std.testing.io, &env);
    defer manifest.deinit();
    try std.testing.expect(manifest.findRunner("first-alias") == null);
    const runner = manifest.findRunner("last-alias").?;
    try std.testing.expectEqualStrings("last", runner.programs[0]);
}

test "XDG configuration adds a profile" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try temporary.dir.createDirPath(std.testing.io, constants.filesystem.config_directory);
    try temporary.dir.writeFile(std.testing.io, .{
        .sub_path = "terminal-theme-run/config.toml",
        .data = "[[runner]]\nname = \"custom-tool\"\naliases = [\"custom-alias\"]\nprograms = [\"custom-binary\"]\n",
    });

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const directory = try temporaryPath(arena.allocator(), &temporary, "");
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try env.put(constants.environment.xdg_config_home, directory);
    var manifest = try Manifest.load(std.testing.allocator, std.testing.io, &env);
    defer manifest.deinit();
    try std.testing.expectEqualStrings("custom-binary", manifest.findRunner("custom-alias").?.programs[0]);
}
