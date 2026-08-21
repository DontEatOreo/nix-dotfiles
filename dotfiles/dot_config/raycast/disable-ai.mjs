#!/usr/bin/env node
import process from "node:process";
import { parseArgs } from "node:util";

import {
  applyDisabled,
  buildSnapshot,
  ensureBackup,
  restore,
  status,
} from "./lib/disable-ai.mjs";
import {
  backupPath,
  DEFAULT_APP_BUNDLE,
  DEFAULT_APP_SUPPORT,
  loadDatabase,
} from "./lib/raycast-database.mjs";

function printUsage() {
  console.log(`Usage: node disable-ai.mjs [--status] [--dry-run] [--restore]

Disables Raycast AI surfaces through Raycast's own local settings database:
- disables internal AI, Dictation, and Translator extensions
- clears Quick AI fallback command exposure
- disables MCP and file-search semantic indexing
- marks all Raycast AI models disabled
- clears selected/last-used AI model defaults
- clears Raycast AI/Dictation/Translator command frecency
- clears Raycast's AI chat window defaults

Environment:
  RAYCAST_APP_SUPPORT          default: ${DEFAULT_APP_SUPPORT}
  RAYCAST_APP_BUNDLE           default: ${DEFAULT_APP_BUNDLE}
  RAYCAST_KEY_FILE             default: latest node runtime .raycast-key-cache
  RAYCAST_AI_DISABLE_BACKUP    default: <app-support>/raycast-ai-disable-backup.json`);
}

function commandOptions(argv) {
  const { values } = parseArgs({
    args: argv,
    options: {
      "dry-run": { type: "boolean" },
      help: { type: "boolean", short: "h" },
      restore: { type: "boolean" },
      status: { type: "boolean" },
    },
    strict: true,
  });

  if (values.restore && values.status) {
    throw new Error("--restore and --status cannot be used together");
  }
  return values;
}

async function run() {
  const args = commandOptions(process.argv.slice(2));
  if (args.help) {
    printUsage();
    return;
  }

  const { db, appSupport, keyFile } = await loadDatabase();

  if (args.status) {
    console.log(JSON.stringify(await status(db), null, 2));
    return;
  }

  if (args.restore) {
    const changes = await restore(db, appSupport, backupPath, args["dry-run"]);
    console.log(
      JSON.stringify(
        { dryRun: args["dry-run"], restored: changes.length, changes },
        null,
        2,
      ),
    );
    return;
  }

  const backup = backupPath(appSupport);
  const before = await buildSnapshot(db);
  const backupWritten = await ensureBackup(backup, before, args["dry-run"]);
  const changes = await applyDisabled(db, before, args["dry-run"]);

  console.log(
    JSON.stringify(
      {
        mode: "disable",
        dryRun: args["dry-run"],
        keyFile,
        backup,
        backupWritten,
        operations: changes.length,
        status: await status(db),
      },
      null,
      2,
    ),
  );
}

run().catch((error) => {
  const message = process.env.DEBUG ? error.stack || error.message : error.message;
  console.error(`disable-ai: ${message}`);
  process.exitCode = 1;
});
