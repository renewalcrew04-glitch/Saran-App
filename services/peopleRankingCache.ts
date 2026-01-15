let cache: {
  key: string;
  data: any[];
  ts: number;
} | null = null;

const TTL = 1000 * 60 * 5; // 5 minutes

export function getCachedPeople(key: string) {
  if (!cache) return null;
  if (Date.now() - cache.ts > TTL) return null;
  if (cache.key !== key) return null;
  return cache.data;
}

export function setCachedPeople(key: string, data: any[]) {
  cache = {
    key,
    data,
    ts: Date.now(),
  };
}
