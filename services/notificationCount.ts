import { db } from "@/services/firebase";
import {
  collection,
  onSnapshot,
  query,
  where,
} from "firebase/firestore";

/**
 * 🔔 Listen unread notifications for current user
 */
export function listenUnreadNotifications(
  uid: string,
  callback: (count: number) => void
) {
  if (!uid) return () => {};

  const q = query(
    collection(db, "notifications", uid, "items"),
    where("read", "==", false)
  );

  return onSnapshot(q, (snap) => {
    callback(snap.size);
  });
}
