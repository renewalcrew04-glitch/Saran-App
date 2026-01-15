import { doc, onSnapshot } from "firebase/firestore";
import { useEffect, useState } from "react";
import { db, auth } from "@/services/firebase";

export function useFollowStatus(targetUid: string) {
  const [isFollowing, setIsFollowing] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const currentUid = auth.currentUser?.uid;
    if (!currentUid) return;

    const ref = doc(
      db,
      "follows",
      currentUid,
      "following",
      targetUid
    );

    const unsub = onSnapshot(ref, (snap) => {
      setIsFollowing(snap.exists());
      setLoading(false);
    });

    return () => unsub();
  }, [targetUid]);

  return { isFollowing, loading };
}
