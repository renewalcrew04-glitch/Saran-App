import { useEffect, useState } from "react";
import { collection, onSnapshot, query, where } from "firebase/firestore";
import { db, auth } from "@/services/firebase";

export function useUnreadNotifications() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const uid = auth.currentUser?.uid;
    if (!uid) return;

    const q = query(
      collection(db, "notifications", uid, "items"),
      where("read", "==", false)
    );

    const unsub = onSnapshot(q, (snap) => {
      setCount(snap.size);
    });

    return unsub;
  }, []);

  return count;
}
