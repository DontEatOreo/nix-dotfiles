const std = @import("std");
const vt = @import("ghostty-vt");
const config = @import("config.zig");
const constants = @import("constants.zig");
const c = @import("c");

pub const ReportParser = struct {
    parser: vt.Parser,
    mode: ?config.Theme = null,

    pub fn init(allocator: std.mem.Allocator) ReportParser {
        var parser = vt.Parser.init();
        parser.osc_parser.alloc = allocator;
        return .{ .parser = parser };
    }

    pub fn deinit(self: *ReportParser) void {
        self.parser.deinit();
    }

    pub fn feed(self: *ReportParser, bytes: []const u8) ?config.Theme {
        for (bytes) |byte| {
            const actions = self.parser.next(byte);
            for (actions) |maybe_action| if (maybe_action) |action| switch (action) {
                .csi_dispatch => |csi| self.consumeCsi(csi),
                .osc_dispatch => |osc| self.consumeOsc(osc),
                else => {},
            };
            if (self.mode != null) return self.mode;
        }
        return self.mode;
    }

    fn consumeCsi(self: *ReportParser, csi: vt.Parser.Action.CSI) void {
        if (csi.final != 'n' or !std.mem.eql(u8, csi.intermediates, "?") or csi.params.len != 2 or csi.params[0] != constants.protocol.color_scheme_report_parameter) return;
        self.mode = switch (csi.params[1]) {
            constants.protocol.dark_report_value => .dark,
            constants.protocol.light_report_value => .light,
            else => null,
        };
    }

    fn consumeOsc(self: *ReportParser, osc: vt.osc.Command) void {
        if (osc != .color_operation or osc.color_operation.op != .osc_11) return;
        var iterator = osc.color_operation.requests.constIterator(0);
        while (iterator.next()) |request| switch (request.*) {
            .set => |colored| switch (colored.target) {
                .dynamic => |dynamic| if (dynamic == .background) {
                    const rgb = colored.color;
                    const luminance = (constants.protocol.luminance_red * @as(f64, @floatFromInt(rgb.r)) + constants.protocol.luminance_green * @as(f64, @floatFromInt(rgb.g)) + constants.protocol.luminance_blue * @as(f64, @floatFromInt(rgb.b))) / constants.protocol.color_channel_maximum;
                    self.mode = if (luminance > constants.protocol.light_luminance_threshold) .light else .dark;
                    return;
                },
                else => {},
            },
            else => {},
        };
    }
};

pub fn parseReport(allocator: std.mem.Allocator, bytes: []const u8) ?config.Theme {
    var parser = ReportParser.init(allocator);
    defer parser.deinit();
    return parser.feed(bytes);
}

pub fn modeFromText(runtime: *const config.Runtime, text: ?[]const u8) ?config.Theme {
    const raw = text orelse return null;
    var normalized = std.mem.trim(u8, raw, constants.text.whitespace);
    if (std.ascii.findIgnoreCase(normalized, @tagName(config.Theme.dark)) != null) return .dark;
    if (std.ascii.findIgnoreCase(normalized, @tagName(config.Theme.light)) != null) return .light;
    if (normalized.len >= 2 and ((normalized[0] == '\'' and normalized[normalized.len - 1] == '\'') or (normalized[0] == '"' and normalized[normalized.len - 1] == '"'))) normalized = normalized[1 .. normalized.len - 1];
    for (runtime.theme_dark_aliases) |alias| if (std.ascii.eqlIgnoreCase(normalized, alias)) return .dark;
    for (runtime.theme_light_aliases) |alias| if (std.ascii.eqlIgnoreCase(normalized, alias)) return .light;
    return null;
}

fn protocol(runtime: *const config.Runtime, identifier: ?[]const u8) ?config.TerminalProtocol {
    const name = identifier orelse return null;
    for (runtime.theme_terminal_queries) |pair| if (std.ascii.eqlIgnoreCase(pair.key, name)) return pair.value;
    return null;
}

pub fn terminalQuery(runtime: *const config.Runtime, env: *const std.process.Environ.Map) []const u8 {
    const selected = protocol(runtime, env.get(runtime.theme_terminal_program_environment)) orelse protocol(runtime, env.get(constants.protocol.terminal_environment)) orelse fallback: {
        for (runtime.theme_terminal_queries) |pair| if (std.mem.eql(u8, pair.key, constants.protocol.wildcard)) break :fallback pair.value;
        break :fallback .background;
    };
    return switch (selected) {
        .background => constants.protocol.background_query,
        .@"color-scheme" => constants.protocol.color_scheme_query,
    };
}

fn probeTerminal(allocator: std.mem.Allocator, io: std.Io, terminal: std.Io.File, query: []const u8, timeout: std.Io.Timeout) ?config.Theme {
    terminal.writeStreamingAll(io, query) catch return null;
    var parser = ReportParser.init(allocator);
    defer parser.deinit();
    var buffer: [constants.protocol.terminal_buffer_bytes]u8 = undefined;
    var used: usize = 0;
    const deadline = timeout.toDeadline(io);
    while (used < buffer.len) {
        const operation = io.operateTimeout(.{ .file_read_streaming = .{
            .file = terminal,
            .data = &.{buffer[used..]},
        } }, deadline) catch break;
        const count = operation.file_read_streaming catch break;
        if (count == 0) break;
        const start = used;
        used += count;
        if (parser.feed(buffer[start..used])) |mode| return mode;
    }
    return parser.mode;
}

fn detectTerminal(allocator: std.mem.Allocator, io: std.Io, runtime: *const config.Runtime, env: *const std.process.Environ.Map) ?config.Theme {
    const terminal = std.Io.Dir.cwd().openFile(io, constants.filesystem.controlling_terminal, .{ .mode = .read_write }) catch return null;
    defer terminal.close(io);
    const saved = std.posix.tcgetattr(terminal.handle) catch return null;
    var raw = saved;
    comptime {
        std.debug.assert(@sizeOf(c.struct_termios) == @sizeOf(std.posix.termios));
        std.debug.assert(@alignOf(c.struct_termios) == @alignOf(std.posix.termios));
    }
    c.cfmakeraw(@ptrCast(&raw));
    std.posix.tcsetattr(terminal.handle, .DRAIN, raw) catch return null;
    defer std.posix.tcsetattr(terminal.handle, .DRAIN, saved) catch {};

    const query = terminalQuery(runtime, env);
    if (probeTerminal(allocator, io, terminal, query, runtime.terminalTimeout())) |mode| return mode;

    // Kitty's color-scheme query reports the user's appearance preference and
    // is therefore preferable to inferring it from a background color. Some
    // multiplexers do not forward that query even when TERM_PROGRAM/TERM
    // identify Kitty or Ghostty, so retry with the
    // widely supported OSC 11 query before falling back to the desktop.
    if (std.mem.eql(u8, query, constants.protocol.color_scheme_query)) {
        return probeTerminal(allocator, io, terminal, constants.protocol.background_query, runtime.terminalTimeout());
    }
    return null;
}

fn commandMode(allocator: std.mem.Allocator, io: std.Io, runtime: *const config.Runtime, env: *const std.process.Environ.Map, command: config.Command) ?config.Theme {
    const result = std.process.run(allocator, io, .{
        .argv = command,
        .environ_map = env,
        .stdout_limit = .limited(runtime.helper_output_limit_bytes),
        .stderr_limit = .limited(runtime.helper_output_limit_bytes),
        .timeout = runtime.helperTimeout(),
    }) catch return null;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    if (result.term != .exited or result.term.exited != 0) return null;
    return modeFromText(runtime, result.stdout);
}

fn detectConfiguredEnvironment(runtime: *const config.Runtime, env: *const std.process.Environ.Map) ?config.Theme {
    for (runtime.theme_environment) |name| if (modeFromText(runtime, env.get(name))) |mode| return mode;
    return null;
}

pub fn detectWithoutTerminal(allocator: std.mem.Allocator, io: std.Io, runtime: *const config.Runtime, env: *const std.process.Environ.Map) config.Theme {
    if (detectConfiguredEnvironment(runtime, env)) |mode| return mode;
    const policy = switch (@import("builtin").os.tag) {
        .macos => .{ runtime.theme_macos_commands, runtime.theme_macos_fallback },
        else => .{ runtime.theme_unix_commands, runtime.theme_unix_fallback },
    };
    for (policy[0]) |command| if (commandMode(allocator, io, runtime, env, command)) |mode| return mode;
    return policy[1];
}

pub fn detect(allocator: std.mem.Allocator, io: std.Io, runtime: *const config.Runtime, env: *const std.process.Environ.Map) config.Theme {
    if (detectConfiguredEnvironment(runtime, env)) |mode| return mode;
    if (detectTerminal(allocator, io, runtime, env)) |mode| return mode;
    return detectWithoutTerminal(allocator, io, runtime, env);
}

test "VT parser handles color scheme responses and fragmentation" {
    var parser = ReportParser.init(std.testing.allocator);
    defer parser.deinit();
    try std.testing.expect(parser.feed("noise\x1b[?997;") == null);
    try std.testing.expectEqual(config.Theme.dark, parser.feed("1n").?);
    try std.testing.expectEqual(config.Theme.light, parseReport(std.testing.allocator, "\x1b[?997;2n").?);
}

test "VT parser handles background color component widths" {
    const cases = [_]struct { report: []const u8, expected: config.Theme }{
        .{ .report = "\x1b]11;rgb:efff/f1f1/f5f5\x07", .expected = .light },
        .{ .report = "prefix\x1b]11;rgb:3030/3434/4646\x1b\\suffix", .expected = .dark },
        .{ .report = "\x1b]11;rgb:f/f/f\x07", .expected = .light },
        .{ .report = "\x1b]11;rgb:ef/f1/f5\x07", .expected = .light },
        .{ .report = "\x1b]11;rgb:000/000/000\x07", .expected = .dark },
        .{ .report = "\x1b]11;rgb:30/34/46\x07", .expected = .dark },
        .{ .report = "\x1b]11;rgb:80/80/80\x07", .expected = .light },
        .{ .report = "\x1b]11;rgb:7f/7f/7f\x07", .expected = .dark },
    };
    for (cases) |case| try std.testing.expectEqual(case.expected, parseReport(std.testing.allocator, case.report).?);
}

test "VT parser rejects malformed terminal reports" {
    const invalid = [_][]const u8{
        "\x1b]11;rgb:/ff/ff\x07",
        "\x1b]11;rgb:fffff/ff/ff\x07",
        "\x1b]11;rgb:gg/ff/ff\x07",
        "\x1b]11;rgb:ff/ff/ff/ff\x07",
        "\x1b[997;1n",
        "\x1b[?997;1;2n",
        "\x1b[?997;1m",
        "\x1b]11;rgb:ff/ff/ff",
        "\x1b]11;rgb:ff/ff/ff\x00ignored\x07",
    };
    for (invalid) |report| try std.testing.expect(parseReport(std.testing.allocator, report) == null);
}

test "text theme detection has no fixed input limit" {
    var text: [4096]u8 = @splat('x');
    @memcpy(text[text.len - 5 ..], "LiGhT");
    const runtime: config.Runtime = undefined;
    try std.testing.expectEqual(config.Theme.light, modeFromText(&runtime, &text).?);
}

test "terminal query selection supports Kitty, Ghostty, and OSC fallback" {
    const runtime: config.Runtime = .{
        .theme_environment = &.{"THEME"},
        .theme_dark_aliases = &.{},
        .theme_light_aliases = &.{},
        .theme_macos_commands = &.{},
        .theme_unix_commands = &.{},
        .theme_terminal_program_environment = "TERM_PROGRAM",
        .theme_terminal_queries = &.{
            .{ .key = "ghostty", .value = .@"color-scheme" },
            .{ .key = "xterm-ghostty", .value = .@"color-scheme" },
            .{ .key = "kitty", .value = .@"color-scheme" },
            .{ .key = "xterm-kitty", .value = .@"color-scheme" },
            .{ .key = constants.protocol.wildcard, .value = .background },
        },
        .theme_macos_fallback = .dark,
        .theme_unix_fallback = .dark,
        .theme_probe_timeout_ms = 1,
        .helper_timeout_ms = 1,
        .helper_output_limit_bytes = 128,
    };
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TERM_PROGRAM", "Ghostty");
    try env.put(constants.protocol.terminal_environment, "xterm-256color");
    try std.testing.expectEqualStrings(constants.protocol.color_scheme_query, terminalQuery(&runtime, &env));

    try env.put("TERM_PROGRAM", "unknown-terminal");
    try env.put(constants.protocol.terminal_environment, "xterm-kitty");
    try std.testing.expectEqualStrings(constants.protocol.color_scheme_query, terminalQuery(&runtime, &env));

    try env.put("TERM_PROGRAM", "");
    try env.put(constants.protocol.terminal_environment, "xterm-ghostty");
    try std.testing.expectEqualStrings(constants.protocol.color_scheme_query, terminalQuery(&runtime, &env));

    try env.put("TERM_PROGRAM", "unknown-terminal");
    try env.put(constants.protocol.terminal_environment, "xterm-256color");
    try std.testing.expectEqualStrings(constants.protocol.background_query, terminalQuery(&runtime, &env));
}
