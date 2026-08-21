const { installDatabaseKeyDump } = require("./lib/keydump-hook.cts") as {
  installDatabaseKeyDump: (keyFile?: string) => void;
};

installDatabaseKeyDump();
