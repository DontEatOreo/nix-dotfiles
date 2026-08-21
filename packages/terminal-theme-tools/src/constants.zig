pub const application = struct {
    pub const name = "terminal-theme-run";
    pub const version = "0.3.0";
    pub const description = "Run a command with terminal theme integration when a matching profile exists.";
};

pub const cli = struct {
    pub const help_option = "--help";
    pub const print_theme_option = "--print-theme";
    pub const print_theme_no_terminal_option = "--print-theme-no-terminal";
    pub const version_option = "--version";
    pub const option_prefix = "--";
    pub const separator = "--";
    pub const first_argument_index = 1;
};

pub const exit = struct {
    pub const success: u8 = 0;
    pub const failure: u8 = 1;
    pub const usage: u8 = 2;
    pub const cannot_execute: u8 = 126;
    pub const not_found: u8 = 127;
    pub const signal_offset: u8 = 128;
};

pub const environment = struct {
    pub const active = "TERMINAL_THEME_RUN_ACTIVE";
    pub const config = "TERMINAL_THEME_RUN_CONFIG";
    pub const home = "HOME";
    pub const path = "PATH";
    pub const temporary_directory = "TMPDIR";
    pub const xdg_cache_home = "XDG_CACHE_HOME";
    pub const xdg_config_home = "XDG_CONFIG_HOME";
};

pub const filesystem = struct {
    pub const config_directory = "terminal-theme-run";
    pub const config_file = "config.toml";
    pub const default_path = ".config/terminal-theme-run/config.toml";
    pub const default_search_path = "/usr/local/bin:/usr/bin:/bin";
    pub const default_cache_directory = ".cache";
    pub const default_temporary_directory = "/tmp";
    pub const max_file_bytes: usize = 1024 * 1024;
    pub const shebang_read_bytes: usize = 512;
    pub const controlling_terminal = "/dev/tty";
};

pub const template = struct {
    pub const theme = "{theme}";
    pub const context = "{context}";
    pub const directory = "{directory}";
    pub const home = "{home}";
};

pub const protocol = struct {
    pub const terminal_environment = "TERM";
    pub const wildcard = "*";
    pub const background_query = "\x1b]11;?\x07";
    pub const color_scheme_query = "\x1b[?996n";
    pub const color_scheme_report_parameter: u16 = 997;
    pub const dark_report_value: u16 = 1;
    pub const light_report_value: u16 = 2;
    pub const osc_background = 11;
    pub const luminance_red = 0.299;
    pub const luminance_green = 0.587;
    pub const luminance_blue = 0.114;
    pub const color_channel_maximum = 255.0;
    pub const light_luminance_threshold = 0.5;
    pub const terminal_buffer_bytes: usize = 128;
};

pub const text = struct {
    pub const whitespace = " \t\r\n";
    pub const horizontal_whitespace = " \t";
    pub const shebang = "#!";
    pub const assignment = " = ";
    pub const table_open = "={";
};

pub const toml = struct {
    pub const temporary_suffix = "XXXXXX";
    pub const runtime_limit_maximum: u64 = 60_000;
};
