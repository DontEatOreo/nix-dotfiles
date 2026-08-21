import {
  type AiDataQuery,
  ENABLEMENT,
  type ExtensionRule,
  OP,
  POLICY,
} from "./config.mts";
import type { RaycastDatabaseClient } from "./db.mts";
import {
  deleteMacOSDefault,
  type MacOSDefaultValue,
  readMacOSDefault,
  restoreMacOSDefault,
} from "./macos.mts";
import type { FrecencyRecord } from "./types.mts";
import {
  asRecord,
  callPath,
  clone,
  count,
  errorMessage,
  getPath,
  isRecord,
  mapEntries,
  pathExists,
  readJson,
  writeJson,
} from "./util.mts";

export type JsonObject = Record<string, unknown>;
export type Operation = {
  type: string;
  apply: () => Promise<unknown> | unknown;
  [key: string]: unknown;
};

export type Snapshot = {
  version: number;
  createdAt: string;
  internalExtensions: Record<string, JsonObject>;
  models: Record<string, { disabledAt?: string | null }>;
  userDefaults: Record<string, unknown>;
  frecencyRecords: FrecencyRecord[];
  macOSDefaults: Record<string, MacOSDefaultValue>;
};

type Collection<K extends keyof Snapshot> = {
  key: K;
  snapshot: (db: RaycastDatabaseClient) => Promise<Snapshot[K]>;
  disable: (input: {
    db: RaycastDatabaseClient;
    value: Snapshot[K];
    now: string;
  }) => Operation[];
  restore: (input: { db: RaycastDatabaseClient; value: Snapshot[K] }) => Operation[];
};

function collection<K extends keyof Snapshot>(spec: Collection<K>): Collection<K> {
  return spec;
}

function op(type: string, fields: JsonObject, apply: Operation["apply"]): Operation {
  return { type, ...fields, apply };
}

export function isRaycastAiItemId(itemId: unknown): itemId is string {
  return (
    typeof itemId === "string" &&
    POLICY.frecencyPrefixes.some((prefix) => itemId.startsWith(prefix))
  );
}

function disabledInternalExtension(
  previous: Record<string, unknown>,
  rule: ExtensionRule,
): Record<string, unknown> {
  if (!previous.id) throw new Error("internal extension settings are missing an id");

  return {
    ...clone(previous),
    enabled:
      "enabled" in rule && rule.enabled === ENABLEMENT.PRESERVE
        ? previous.enabled
        : false,
    syncedMeta: {
      ...asRecord(previous.syncedMeta),
      ...("syncedMeta" in rule ? rule.syncedMeta : {}),
    },
    localMeta: {
      ...asRecord(previous.localMeta),
      ...("localMeta" in rule ? rule.localMeta : {}),
    },
    enabledFallbackCommandIds:
      "enabledFallbackCommandIds" in rule
        ? clone(rule.enabledFallbackCommandIds)
        : clone(previous.enabledFallbackCommandIds ?? []),
  };
}

const COLLECTIONS = [
  collection({
    key: "internalExtensions",
    snapshot: (db) =>
      mapEntries(POLICY.internalExtensions, async ({ id }) => [
        id,
        clone((await db.settings.getInternalExtensionSettings(id)) ?? {}),
      ]),
    disable: ({ db, value }) =>
      POLICY.internalExtensions.flatMap((rule) => {
        const previous = value[rule.id];
        if (!previous?.id) return [];
        const next = disabledInternalExtension(previous, rule);
        return [
          op(
            OP.INTERNAL_EXTENSION,
            {
              id: rule.id,
              enabled: next.enabled,
              clearedFallbackCommands:
                "enabledFallbackCommandIds" in rule ? POLICY.fallbackCommandIds : [],
            },
            () => db.settings.updateInternalExtensionSettings(rule.id, next),
          ),
        ];
      }),
    restore: ({ db, value }) =>
      Object.entries(value).map(([id, previous]) =>
        op(OP.INTERNAL_EXTENSION, { id, enabled: previous.enabled }, () =>
          db.settings.updateInternalExtensionSettings(id, previous),
        ),
      ),
  }),
  collection({
    key: "models",
    snapshot: async (db) =>
      Object.fromEntries(
        (await db.ai.modelGetAll()).map((model) => [
          model.id,
          { disabledAt: model.disabledAt ?? null },
        ]),
      ),
    disable: ({ db, value, now }) =>
      Object.keys(value).map((id) =>
        op(OP.MODEL, { id, disabledAt: now }, () => db.ai.modelSetDisabledAt(id, now)),
      ),
    restore: ({ db, value }) =>
      Object.entries(value).map(([id, previous]) => {
        const disabledAt = previous.disabledAt ?? null;
        return op(OP.MODEL, { id, disabledAt }, () =>
          db.ai.modelSetDisabledAt(id, disabledAt),
        );
      }),
  }),
  collection({
    key: "userDefaults",
    snapshot: (db) =>
      mapEntries(POLICY.modelUserDefaultKeys, async (key) => [
        key,
        await db.userDefaults.get(key),
      ]),
    disable: ({ db, value }) =>
      Object.keys(value).map((key) =>
        op(OP.USER_DEFAULT, { key, value: null }, () => db.userDefaults.delete(key)),
      ),
    restore: ({ db, value }) =>
      Object.entries(value).map(([key, stored]) =>
        op(OP.USER_DEFAULT, { key, value: stored }, () =>
          stored == null
            ? db.userDefaults.delete(key)
            : db.userDefaults.set(
                key,
                typeof stored === "string" ? stored : JSON.stringify(stored),
              ),
        ),
      ),
  }),
  collection({
    key: "frecencyRecords",
    snapshot: async (db) =>
      (await db.frecency.getAll()).filter((record) => isRaycastAiItemId(record.itemId)),
    disable: ({ db, value }) =>
      value.map((record) =>
        op(OP.FRECENCY, { itemId: record.itemId, action: "reset" }, () =>
          db.frecency.reset(record.itemId),
        ),
      ),
    restore: ({ db, value }) =>
      value.length
        ? [
            op(OP.FRECENCY, { restoredRecords: value.length }, () =>
              db.frecency.insertMany(value),
            ),
          ]
        : [],
  }),
  collection({
    key: "macOSDefaults",
    snapshot: () =>
      mapEntries(POLICY.macOSDefaults, async (rule) => [
        rule.key,
        await readMacOSDefault(rule),
      ]),
    disable: ({ value }) =>
      Object.keys(value).map((key) =>
        op(OP.MACOS_DEFAULT, { key, action: "delete" }, () =>
          deleteMacOSDefault({ key }),
        ),
      ),
    restore: ({ value }) =>
      Object.entries(value).map(([key, defaultValue]) =>
        op(OP.MACOS_DEFAULT, { key, exists: defaultValue.exists }, () =>
          restoreMacOSDefault(defaultValue),
        ),
      ),
  }),
] as const;

async function runOperations(
  operations: Operation[],
  dryRun: boolean,
): Promise<JsonObject[]> {
  if (!dryRun) {
    for (const current of operations) await current.apply();
  }
  return operations.map(({ apply: _apply, ...summary }) => summary);
}

type AnyCollection = (typeof COLLECTIONS)[number];

export async function buildSnapshot(db: RaycastDatabaseClient): Promise<Snapshot> {
  const snapshot = {
    version: POLICY.backupVersion,
    createdAt: new Date().toISOString(),
  } as Snapshot;

  await Promise.all(
    COLLECTIONS.map(async (entry) => {
      Object.assign(snapshot, { [entry.key]: await entry.snapshot(db) });
    }),
  );
  return snapshot;
}

function runCollection(
  entry: AnyCollection,
  db: RaycastDatabaseClient,
  value: Snapshot[AnyCollection["key"]],
  now?: string,
): Operation[] {
  return now === undefined
    ? entry.restore({ db, value: value as never })
    : entry.disable({ db, value: value as never, now });
}

export async function applyDisabled(
  db: RaycastDatabaseClient,
  before: Snapshot,
  dryRun: boolean,
): Promise<JsonObject[]> {
  const now = new Date().toISOString();
  return runOperations(
    COLLECTIONS.flatMap((entry) => runCollection(entry, db, before[entry.key], now)),
    dryRun,
  );
}

function asSnapshot(value: unknown): Snapshot {
  if (!isRecord(value) || typeof value.version !== "number") {
    throw new Error("invalid Raycast AI disable backup");
  }
  if (value.version !== POLICY.backupVersion) {
    throw new Error(`unsupported backup version: ${value.version}`);
  }
  return value as Snapshot;
}

function mergeMissing(target: JsonObject, source: JsonObject): boolean {
  let changed = false;
  for (const [key, value] of Object.entries(source)) {
    if (target[key] !== undefined) continue;
    target[key] = value;
    changed = true;
  }
  return changed;
}

export async function ensureBackup(
  file: string,
  before: Snapshot,
  dryRun: boolean,
): Promise<boolean> {
  if (dryRun) return false;

  if (!(await pathExists(file))) {
    await writeJson(file, before);
    return true;
  }

  const existing = asSnapshot(await readJson(file));
  let changed = mergeMissing(existing as JsonObject, before as JsonObject);
  for (const key of POLICY.mergeableBackupCollections) {
    const incoming = asRecord(before[key as keyof Snapshot]);
    if (!incoming) continue;
    const slot = key as keyof Snapshot;
    if (!asRecord(existing[slot])) existing[slot] = {} as never;
    const target = asRecord(existing[slot]);
    if (!target) continue;
    changed = mergeMissing(target, incoming) || changed;
  }

  if (changed) await writeJson(file, existing);
  return changed;
}

export async function restore(
  db: RaycastDatabaseClient,
  appSupport: string,
  backupPathFor: (appSupport: string) => string,
  dryRun: boolean,
): Promise<JsonObject[]> {
  const file = backupPathFor(appSupport);
  if (!(await pathExists(file))) throw new Error(`backup not found: ${file}`);

  const backup = asSnapshot(await readJson(file));
  return runOperations(
    COLLECTIONS.flatMap((entry) =>
      runCollection(entry, db, backup[entry.key] ?? emptyValue(entry.key)),
    ),
    dryRun,
  );
}

function emptyValue<K extends keyof Snapshot>(key: K): Snapshot[K] {
  return (key === "frecencyRecords" ? [] : {}) as Snapshot[K];
}

async function queryAiData(
  db: RaycastDatabaseClient,
  query: AiDataQuery,
): Promise<readonly [string, unknown]> {
  try {
    const records = await callPath(db, query.methodPath);
    if (!("filter" in query) || !query.filter) return [query.key, count(records)];
    if (!Array.isArray(records)) return [query.key, 0];
    return [
      query.key,
      records.filter((item) => getPath(item, query.filter.path) === query.filter.equals)
        .length,
    ];
  } catch (error) {
    return [query.key, { error: errorMessage(error) }];
  }
}

export async function status(
  db: RaycastDatabaseClient,
): Promise<Record<string, unknown>> {
  const [internalExtensions, models, frecencyRecords, macOSDefaults, aiData] =
    await Promise.all([
      mapEntries(POLICY.internalExtensions, async ({ id }) => {
        const item = asRecord(await db.settings.getInternalExtensionSettings(id));
        if (!item?.id) return [id, { present: false }];
        return [
          id,
          {
            present: true,
            ...Object.fromEntries(
              POLICY.statusFields.map((field) => [
                field.key,
                getPath(item, field.path) ??
                  clone("defaultValue" in field ? field.defaultValue : undefined),
              ]),
            ),
          },
        ];
      }),
      db.ai.modelGetAll(),
      db.frecency
        .getAll()
        .then((records) =>
          records.filter((record) => isRaycastAiItemId(record.itemId)),
        ),
      mapEntries(POLICY.macOSDefaults, async (rule) => [
        rule.key,
        await readMacOSDefault(rule),
      ]),
      mapEntries(POLICY.aiDataQueries, (query) => queryAiData(db, query)),
    ]);

  return {
    internalExtensions,
    modelCount: models.length,
    disabledModelCount: models.filter((model) => model.disabledAt != null).length,
    aiFrecencyCount: frecencyRecords.length,
    aiData,
    macOSDefaults,
  };
}
