/**
 * Codex quota proxy via CPA plugin codex-sticky-fingerprint.
 * Response matches /api-call shape: status_code, header, body.
 */

import type { AxiosRequestConfig } from 'axios';
import { apiClient } from './client';
import type { ApiCallResult } from './apiCall';

const PLUGIN_ID = 'codex-sticky-fingerprint';

const ROUTE_QUOTA = `/plugins/${PLUGIN_ID}/quota`;
const ROUTE_RESET_CREDITS = `/plugins/${PLUGIN_ID}/reset-credits`;
const ROUTE_RESET_CONSUME = `/plugins/${PLUGIN_ID}/reset-credits/consume`;

const normalizeBody = (input: unknown): { bodyText: string; body: unknown | null } => {
  if (input === undefined || input === null) {
    return { bodyText: '', body: null };
  }
  if (typeof input === 'string') {
    const text = input;
    const trimmed = text.trim();
    if (!trimmed) {
      return { bodyText: text, body: null };
    }
    try {
      return { bodyText: text, body: JSON.parse(trimmed) };
    } catch {
      return { bodyText: text, body: text };
    }
  }
  try {
    return { bodyText: JSON.stringify(input), body: input };
  } catch {
    return { bodyText: String(input), body: input };
  }
};

const parseManagementEnvelope = (raw: unknown): ApiCallResult => {
  if (typeof raw === 'string') {
    const trimmed = raw.trim();
    if (!trimmed) {
      return { statusCode: 0, header: {}, bodyText: '', body: null };
    }
    try {
      return parseManagementEnvelope(JSON.parse(trimmed));
    } catch {
      return { statusCode: 0, header: {}, bodyText: raw, body: raw };
    }
  }
  if (!raw || typeof raw !== 'object') {
    return { statusCode: 0, header: {}, bodyText: '', body: null };
  }
  const record = raw as Record<string, unknown>;
  const statusCode = Number(record.status_code ?? 0);
  const header = (record.header ?? {}) as Record<string, string[]>;
  const { bodyText, body } = normalizeBody(record.body);
  return { statusCode, header, bodyText, body };
};

const postPluginProxy = async (
  path: string,
  payload: Record<string, string>,
  config?: AxiosRequestConfig
): Promise<ApiCallResult> => {
  const response = await apiClient.post<unknown>(path, payload, config);
  return parseManagementEnvelope(response);
};

export const CODEX_STICKY_FINGERPRINT_PLUGIN_ID = PLUGIN_ID;

export const codexStickyFingerprintApi = {
  fetchQuota: (authIndex: string, config?: AxiosRequestConfig) =>
    postPluginProxy(ROUTE_QUOTA, { auth_index: authIndex }, config),

  fetchResetCredits: (authIndex: string, config?: AxiosRequestConfig) =>
    postPluginProxy(ROUTE_RESET_CREDITS, { auth_index: authIndex }, config),

  consumeResetCredit: (
    authIndex: string,
    redeemRequestId: string,
    config?: AxiosRequestConfig
  ) =>
    postPluginProxy(
      ROUTE_RESET_CONSUME,
      { auth_index: authIndex, redeem_request_id: redeemRequestId },
      config
    ),
};