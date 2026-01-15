import { useEffect, useState } from "react";
import {
  collectionGroup,
  onSnapshot,
  query,
  where,
} from "firebase/firestore";
import { auth, db } from "@/services/firebase";

/**
 * Counts unread messages for current user
 */
export function useUnreadMessages() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const uid = auth.currentUser?.uid;
    if (!uid) return;

    const q = query(
      collectionGroup(db, "messages"),
      where("receiverUid", "==", uid),
      where("read", "==", false)
    );

    return onSnapshot(q, (snap) => {
      setCount(snap.size);
    });
  }, []);

  return count;
}
