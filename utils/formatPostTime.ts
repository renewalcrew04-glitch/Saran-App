import { Timestamp } from "firebase/firestore";
export function hoursAgo(ts: number) {
  return Math.floor((Date.now() - ts) / 3600000) + "h";
}
export function formatPostTime(createdAt: Timestamp) {
  if (!createdAt) return "";

  const now = Date.now();
  const time = createdAt.toDate().getTime();
  const diffSeconds = Math.floor((now - time) / 1000);

  // Just now
  if (diffSeconds < 60) {
    return "Just now";
  }

  // Minutes (up to 60 mins)
  if (diffSeconds < 3600) {
    const mins = Math.floor(diffSeconds / 60);
    return `${mins}m`;
  }

  // Hours (up to 24 hours)
  if (diffSeconds < 86400) {
    const hrs = Math.floor(diffSeconds / 3600);
    return `${hrs}h`;
  }

  // Days (up to 5 days)
  if (diffSeconds < 432000) {
    const days = Math.floor(diffSeconds / 86400);
    return `${days}d`;
  }

  // Date (dd MMM yy)
  return createdAt.toDate().toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "2-digit",
  });
}
