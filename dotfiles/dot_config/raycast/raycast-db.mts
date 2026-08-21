#!/usr/bin/env node
import process from "node:process";
import { parseArgs } from "node:util";

import { assertSupportedNode, PATHS, runtimeReport } from "./lib/config.mts";
import { type RaycastDatabaseClient, withDatabase } from "./lib/db.mts";
import {
  addonSurface,
  databaseMethodSurface,
  databaseSummary,
  parseStoredJson,
  profileDefaults,
  resolveDatabaseMethod,
  userDefaultValue,
} from "./lib/inspect.mts";
import {
  applyProfileDefaults,
  parseProfilePayload,
  profileSummary,
} from "./lib/profile.mts";
import { isRecord, printJson, requiredString, runCli } from "./lib/util.mts";

const FLAGS = { "dry-run": { type: "boolean" } } as const;

type Flags = { dryRun: boolean; positionals: string[] };

type Command = {
  help: string;
  usage?: string;
  run: (flags: Flags) => unknown | Promise<unknown>;
};

function parseArgv(argv: string[]): Flags {
  const { positionals, values } = parseArgs({
    allowPositionals: true,
    args: argv,
    options: FLAGS,
    strict: true,
  });
  return { dryRun: values["dry-run"] ?? false, positionals };
}

function parseJsonArgs(value: string | undefined): unknown[] {
  if (value === undefined) return [];
  const parsed: unknown = JSON.parse(value);
  if (!Array.isArray(parsed)) throw new Error("method args must be a JSON array");
  return parsed;
}

function parseAliasPayload(value: unknown): Array<{
  id: string;
  extensionId: string;
  alias: string | null;
  enabled?: boolean;
}> {
  if (!Array.isArray(value)) throw new Error("aliases payload must be a JSON array");

  return value.map((entry, index) => {
    const record = isRecord(entry)
      ? entry
      : (() => {
          throw new Error(`alias entry ${index} must be an object`);
        })();
    const alias = record.alias;
    if (alias !== null && typeof alias !== "string") {
      throw new Error(`alias entry ${index} alias must be a string or null`);
    }
    if (typeof alias === "string" && /\s/.test(alias)) {
      throw new Error(`alias entry ${index} alias cannot contain whitespace`);
    }

    return {
      id: requiredString(record.id, `alias entry ${index} id`),
      extensionId: requiredString(
        record.extensionId ?? record.extension_id,
        `alias entry ${index} extensionId`,
      ),
      alias: alias === "" ? null : alias,
      ...(typeof record.enabled === "boolean" ? { enabled: record.enabled } : {}),
    };
  });
}

async function applyCommandAliases(
  db: RaycastDatabaseClient,
  aliases: ReturnType<typeof parseAliasPayload>,
  dryRun: boolean,
): Promise<object[]> {
  return Promise.all(
    aliases.map(async (entry) => {
      const before = await db.settings.getCommandSettings(entry.id);
      const update = {
        id: entry.id,
        extensionId: entry.extensionId,
        enabled: entry.enabled ?? before?.enabled ?? true,
        alias: entry.alias,
      };
      if (!dryRun) {
        await (before
          ? db.settings.updateCommandSettings(entry.id, update)
          : db.settings.addCommandSettings(update));
      }
      return {
        id: entry.id,
        before,
        ...(dryRun
          ? { plannedAfter: { ...before, ...update } }
          : { after: await db.settings.getCommandSettings(entry.id) }),
      };
    }),
  );
}

const USER_DEFAULT_ACTIONS = {
  get: {
    usage: "user-default get <key>",
    run: async ({ db, key }: { db: RaycastDatabaseClient; key: string }) => ({
      key,
      value: await userDefaultValue(db, key),
    }),
  },
  delete: {
    usage: "user-default delete <key> [--dry-run]",
    run: async ({
      db,
      key,
      dryRun,
    }: {
      db: RaycastDatabaseClient;
      key: string;
      dryRun: boolean;
    }) => {
      const before = await userDefaultValue(db, key);
      if (!dryRun) await db.userDefaults.delete(key);
      return {
        dryRun,
        key,
        action: "delete",
        before,
        ...(dryRun ? { plannedAfter: null } : { after: null }),
      };
    },
  },
  set: {
    usage: "user-default set <key> <value> [--dry-run]",
    run: writeUserDefault,
  },
  "set-json": {
    usage: "user-default set-json <key> <json> [--dry-run]",
    run: writeUserDefault,
  },
} as const;

async function writeUserDefault({
  db,
  action,
  key,
  value,
  dryRun,
}: {
  db: RaycastDatabaseClient;
  action: "set" | "set-json";
  key: string;
  value: string | undefined;
  dryRun: boolean;
}): Promise<unknown> {
  if (value === undefined)
    throw new Error(`usage: user-default ${action} <key> <value>`);
  const stored = action === "set-json" ? JSON.stringify(JSON.parse(value)) : value;
  const before = await userDefaultValue(db, key);
  if (!dryRun) await db.userDefaults.set(key, stored);
  return {
    dryRun,
    key,
    action,
    before,
    ...(dryRun
      ? { plannedAfter: parseStoredJson(stored) }
      : { after: await userDefaultValue(db, key) }),
  };
}

function isUserDefaultAction(
  action: string,
): action is keyof typeof USER_DEFAULT_ACTIONS {
  return action in USER_DEFAULT_ACTIONS;
}

const COMMANDS = {
  runtime: {
    help: "Print the Node/TypeScript contract these scripts were checked against.",
    run: () => runtimeReport(),
  },
  surface: {
    help: "Print native addon exports and repository methods without opening the DB.",
    run: () => addonSurface(),
  },
  status: {
    help: "Print database initialization and health status.",
    run: () =>
      withDatabase(async ({ db, appSupport, keyFile }) => ({
        appSupport,
        keyFile,
        initReport: db.initReport,
        status: await db.getDatabaseStatus(),
      })),
  },
  summary: {
    help: "Print concise counts/settings.",
    run: () =>
      withDatabase(async ({ db, appSupport, keyFile }) => ({
        appSupport,
        keyFile,
        summary: await databaseSummary(db),
      })),
  },
  methods: {
    help: "Print callable DatabaseClient and repository methods.",
    run: () => withDatabase(async ({ db }) => databaseMethodSurface(db)),
  },
  call: {
    help: "Invoke any DatabaseClient/repository method with JSON positional args.",
    usage: "call <method.path> [json-args] [--dry-run]",
    run: async ({ dryRun, positionals }: Flags) => {
      const [methodPath, jsonArgs, ...unexpected] = positionals;
      if (!methodPath || unexpected.length > 0) {
        throw new Error("usage: call <method.path> [json-args]");
      }
      const args = parseJsonArgs(jsonArgs);
      if (dryRun) return { dryRun, method: methodPath, args };
      return withDatabase(async ({ db }) => {
        const { method, receiver } = resolveDatabaseMethod(db, methodPath);
        return { method: methodPath, args, result: await method.apply(receiver, args) };
      });
    },
  },
  profile: {
    help: "Print or write CurrentUser and OAuthTokenResponse user defaults.",
    usage: "profile [apply <current-user-json> <oauth-token-json> [--dry-run]]",
    run: async ({ dryRun, positionals }: Flags) => {
      const [action, currentUser, oauthToken] = positionals;
      if (!action) return withDatabase(async ({ db }) => profileDefaults(db));
      if (action !== "apply") throw new Error(`unknown profile action: ${action}`);
      const profile = parseProfilePayload(currentUser, oauthToken);
      if (dryRun) return { dryRun, profile };
      return withDatabase(async ({ db }) => {
        const stored = await applyProfileDefaults(db, profile);
        return { summary: profileSummary(stored), stored };
      });
    },
  },
  aliases: {
    help: "Upsert command aliases from JSON.",
    usage: "aliases apply <aliases-json> [--dry-run]",
    run: async ({ dryRun, positionals }: Flags) => {
      const [action, payload, ...unexpected] = positionals;
      if (action !== "apply" || !payload || unexpected.length > 0) {
        throw new Error("usage: aliases apply <aliases-json> [--dry-run]");
      }
      const aliases = parseAliasPayload(JSON.parse(payload));
      return withDatabase(async ({ db }) => ({
        dryRun,
        aliases: await applyCommandAliases(db, aliases, dryRun),
      }));
    },
  },
  "user-default": {
    help: "Get, set, or delete one Raycast user default.",
    usage: "user-default <get|set|set-json|delete> <key> [value] [--dry-run]",
    run: async ({ dryRun, positionals }: Flags) => {
      const [action, key, value] = positionals;
      if (!action || !key || !isUserDefaultAction(action)) {
        throw new Error("usage: user-default <get|set|set-json|delete> <key>");
      }
      return withDatabase(async ({ db }) => {
        if (action === "set" || action === "set-json") {
          return writeUserDefault({ db, action, key, value, dryRun });
        }
        return USER_DEFAULT_ACTIONS[action].run({ db, key, dryRun });
      });
    },
  },
} as const satisfies Record<string, Command>;

function isCommand(name: string): name is keyof typeof COMMANDS {
  return name in COMMANDS;
}

function printUsage(): void {
  const commands = Object.entries(COMMANDS)
    .map(([name, command]) => {
      const heading = "usage" in command && command.usage ? command.usage : name;
      return `  ${heading}\n      ${command.help}`;
    })
    .join("\n");

  console.log(`Usage: node raycast-db.mts <command> [options]

Commands:
${commands}

Environment:
${Object.values(PATHS.env)
  .map((name) => `  ${name}`)
  .join("\n")}`);
}

async function run(): Promise<void> {
  assertSupportedNode();
  const [commandName, ...argv] = process.argv.slice(2);
  if (!commandName || commandName === "--help" || commandName === "-h") {
    printUsage();
    return;
  }
  if (!isCommand(commandName)) throw new Error(`unknown command: ${commandName}`);
  const result = await COMMANDS[commandName].run(parseArgv(argv));
  if (result !== undefined) printJson(result);
}

runCli("raycast-db", run);
