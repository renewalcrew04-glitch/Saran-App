export function extractMentions(text: string): string[] {
  const matches = text.match(/@([a-zA-Z0-9_]+)/g);
  if (!matches) return [];
  return matches.map((m) => m.substring(1).toLowerCase());
}
