import { access, readFile, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import process from "node:process";

import { IO } from "./config.mts";

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function asRecord(value: unknown): Record<string, unknown> | undefined {
  return isRecord(value) ? value : undefined;
}

export function expandHome(value: string): string;
export function expandHome(value: string | undefined): string | undefined;
export function expandHome(value: string | undefined): string | undefined {
  return value?.startsWith("~/") ? path.join(os.homedir(), value.slice(2)) : value;
}

export async function pathExists(file: string): Promise<boolean> {
  return access(file).then(
    () => true,
    () => false,
  );
}

export async function readJson(file: string): Promise<unknown> {
  return JSON.parse(await readFile(file, "utf8"));
}

export async function writeJson(file: string, value: unknown): Promise<void> {
  await writeFile(file, `${JSON.stringify(value, null, IO.JSON_INDENT)}\n`, {
    mode: IO.FILE_MODE,
  });
}

export function clone<T>(value: T): T {
  return value == null ? value : structuredClone(value);
}

export function count(value: unknown): number {
  if (Array.isArray(value)) return value.length;
  if (value == null) return 0;
  if (typeof value === "object") return Object.keys(value).length;
  return 0;
}

export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

export function getPath(value: unknown, segments: readonly string[]): unknown {
  return segments.reduce<unknown>((current, key) => asRecord(current)?.[key], value);
}

export async function callPath(
  source: unknown,
  segments: readonly string[],
  args: readonly unknown[] = [],
): Promise<unknown> {
  if (segments.length === 0) throw new Error("method path must not be empty");
  const method = getPath(source, segments);
  const receiver =
    segments.length === 1 ? source : getPath(source, segments.slice(0, -1));
  if (typeof method !== "function") {
    throw new Error(`missing Raycast database method: ${segments.join(".")}`);
  }
  return (method as (...methodArgs: unknown[]) => unknown).apply(receiver, [...args]);
}

export async function mapEntries<T, K extends string, V>(
  items: readonly T[],
  pair: (item: T) => Promise<readonly [K, V]>,
): Promise<Record<K, V>> {
  return Object.fromEntries(await Promise.all(items.map(pair))) as Record<K, V>;
}

export function requiredString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`${label} is required`);
  }
  return value;
}

export function parseJsonObject(text: string, label: string): Record<string, unknown> {
  const value: unknown = JSON.parse(text);
  if (!isRecord(value)) throw new Error(`${label} must be a JSON object`);
  return value;
}

export function printJson(value: unknown): void {
  console.log(JSON.stringify(value, null, IO.JSON_INDENT));
}

export function runCli(name: string, start: () => Promise<void>): void {
  start().catch((error: unknown) => {
    const message =
      process.env.DEBUG && error instanceof Error ? error.stack : errorMessage(error);
    console.error(`${name}: ${message}`);
    process.exitCode = 1;
  });
}
