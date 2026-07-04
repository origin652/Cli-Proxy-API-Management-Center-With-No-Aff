/**
 * Detect whether CPA has codex-sticky-fingerprint enabled (for quota proxy fallback).
 */

import { CODEX_STICKY_FINGERPRINT_PLUGIN_ID } from '@/services/api/codexStickyFingerprint';
import { pluginsApi } from '@/services/api';

let cachedEnabled: boolean | null = null;
let cacheAt = 0;
const CACHE_MS = 30_000;

export const resetCodexStickyPluginCache = (): void => {
  cachedEnabled = null;
  cacheAt = 0;
};

export const isCodexStickyFingerprintPluginActive = async (): Promise<boolean> => {
  const now = Date.now();
  if (cachedEnabled !== null && now - cacheAt < CACHE_MS) {
    return cachedEnabled;
  }
  try {
    const list = await pluginsApi.list();
    if (!list.pluginsEnabled) {
      cachedEnabled = false;
      cacheAt = now;
      return false;
    }
    const entry = list.plugins.find((p) => p.id === CODEX_STICKY_FINGERPRINT_PLUGIN_ID);
    const active = Boolean(entry?.registered && entry.effectiveEnabled);
    cachedEnabled = active;
    cacheAt = now;
    return active;
  } catch {
    cachedEnabled = false;
    cacheAt = now;
    return false;
  }
};