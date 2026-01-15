import { notify } from "@/services/notify";

export function extractMentions(text: string): string[] {
  const matches = text.match(/@[\w]+/g);
  return matches ? matches.map((m) => m.slice(1)) : [];
}
