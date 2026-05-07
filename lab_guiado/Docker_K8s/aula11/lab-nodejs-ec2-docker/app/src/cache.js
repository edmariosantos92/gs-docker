import Redis from 'ioredis';
import { config } from './config.js';

let client;
let disabled = false;

export function isCacheConfigured() {
  return Boolean(config.cache.host);
}

export function getCache() {
  if (!isCacheConfigured() || disabled) return null;
  if (!client) {
    client = new Redis({
      host: config.cache.host,
      port: config.cache.port,
      tls: config.cache.tls ? {} : undefined,
      lazyConnect: true,
      maxRetriesPerRequest: 1,
      enableOfflineQueue: false,
      connectTimeout: 1500
    });
    client.on('error', (err) => {
      console.warn('[cache] Valkey indisponível:', err.message);
    });
  }
  return client;
}

export async function pingCache() {
  const cache = getCache();
  if (!cache) return { configured: false, ok: false };
  try {
    if (cache.status === 'wait') await cache.connect();
    const pong = await cache.ping();
    return { configured: true, ok: pong === 'PONG' };
  } catch (err) {
    return { configured: true, ok: false, error: err.message };
  }
}

export async function getJson(key) {
  const cache = getCache();
  if (!cache) return null;
  try {
    if (cache.status === 'wait') await cache.connect();
    const value = await cache.get(key);
    return value ? JSON.parse(value) : null;
  } catch (err) {
    console.warn('[cache] leitura falhou:', err.message);
    return null;
  }
}

export async function setJson(key, value, ttlSeconds = config.cache.ttlSeconds) {
  const cache = getCache();
  if (!cache) return;
  try {
    if (cache.status === 'wait') await cache.connect();
    await cache.set(key, JSON.stringify(value), 'EX', ttlSeconds);
  } catch (err) {
    console.warn('[cache] escrita falhou:', err.message);
  }
}

export async function closeCache() {
  if (client) {
    disabled = true;
    await client.quit().catch(() => undefined);
  }
}
