import { PATHS, SUMMARY } from "./config.mts";
import {
  dataAddonPath,
  loadRaycastDataAddon,
  type RaycastDatabaseClient,
} from "./db.mts";
import { callPath, count, errorMessage, getPath, isRecord } from "./util.mts";

export type MethodResolution = {
  method: (...args: unknown[]) => unknown;
  receiver: Record<string, unknown>;
};

export function parseStoredJson(value: unknown): unknown {
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

function prototypeMethods(value: unknown): string[] {
  if (typeof value !== "function") return [];
  return Object.getOwnPropertyNames(value.prototype ?? {}).filter(
    (name) => name !== "constructor",
  );
}

function callableMethods(value: object): string[] {
  return Object.getOwnPropertyNames(Object.getPrototypeOf(value) ?? {}).filter(
    (name) => name !== "constructor" && typeof Reflect.get(value, name) === "function",
  );
}

export function addonSurface(): {
  addon: string;
  exports: Record<string, { type: string; methods?: string[] }>;
} {
  const addon = loadRaycastDataAddon();
  return {
    addon: dataAddonPath(),
    exports: Object.fromEntries(
      Object.keys(addon)
        .toSorted()
        .map((name) => {
          const value = addon[name];
          const type = typeof value;
          return [
            name,
            type === "function" ? { type, methods: prototypeMethods(value) } : { type },
          ];
        }),
    ),
  };
}

export function databaseMethodSurface(db: RaycastDatabaseClient): {
  client: { methods: string[] };
  repositories: Record<string, { methods: string[] }>;
} {
  const getters = Object.entries(
    Object.getOwnPropertyDescriptors(Object.getPrototypeOf(db) ?? {}),
  )
    .filter(([, descriptor]) => typeof descriptor.get === "function")
    .map(([name]) => name);

  return {
    client: { methods: callableMethods(db) },
    repositories: Object.fromEntries(
      getters.flatMap((name) => {
        const value = db[name];
        return value && typeof value === "object"
          ? [[name, { methods: callableMethods(value) }]]
          : [];
      }),
    ),
  };
}

export function resolveDatabaseMethod(
  db: RaycastDatabaseClient,
  methodPath: string,
): MethodResolution {
  const segments = methodPath.split(".").filter(Boolean);
  const method = getPath(db, segments);
  const receiver = segments.length <= 1 ? db : getPath(db, segments.slice(0, -1));
  if (typeof method !== "function" || !isRecord(receiver)) {
    throw new Error(`unknown database method: ${methodPath}`);
  }
  return { method: method as (...args: unknown[]) => unknown, receiver };
}

async function optionalCount(
  label: string,
  read: () => Promise<unknown>,
): Promise<readonly [string, number | { error: string }]> {
  try {
    return [label, count(await read())];
  } catch (error) {
    return [label, { error: errorMessage(error) }];
  }
}

export async function databaseSummary(
  db: RaycastDatabaseClient,
): Promise<Record<string, unknown>> {
  const [databaseStatus, generalSettings, internalExtensions, ...countEntries] =
    await Promise.all([
      db.getDatabaseStatus(),
      db.settings.getGeneralSettings(),
      db.settings.allInternalExtensionsSettings(),
      ...SUMMARY.counts.map((query) =>
        optionalCount(query.key, async () => {
          const value = await callPath(db, query.methodPath, query.args ?? []);
          return query.select ? getPath(value, [query.select]) : value;
        }),
      ),
    ]);

  return {
    databases: databaseStatus,
    generalSettings: Object.fromEntries(
      SUMMARY.generalSettings.map((key) => [key, generalSettings[key]]),
    ),
    internalExtensions: {
      total: internalExtensions.length,
      enabled: internalExtensions.filter((extension) => extension.enabled).length,
      disabled: internalExtensions
        .filter((extension) => !extension.enabled)
        .map((extension) => extension.id)
        .toSorted(),
    },
    counts: Object.fromEntries(countEntries),
  };
}

export async function profileDefaults(
  db: RaycastDatabaseClient,
): Promise<{ currentUser: unknown; oauthToken: unknown }> {
  const { currentUser, oauthToken } = PATHS.profileUserDefaults;
  const [current, oauth] = await Promise.all([
    db.userDefaults.get(currentUser),
    db.userDefaults.get(oauthToken),
  ]);
  return {
    currentUser: parseStoredJson(current),
    oauthToken: parseStoredJson(oauth),
  };
}

export async function userDefaultValue(
  db: RaycastDatabaseClient,
  key: string,
): Promise<unknown> {
  return parseStoredJson(await db.userDefaults.get(key));
}
