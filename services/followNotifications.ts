import {
  doc,
  setDoc,
  serverTimestamp,
  getDoc,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";

export async function notifyFollow(targetUid: string) {
  const fromUid = auth.currentUser?.uid;
  if (!fromUid || fromUid === targetUid) return;

  const profileSnap = await getDoc(
    doc(db, "profiles", fromUid)
  );

  const profile = profileSnap.exists()
    ? profileSnap.data()
    : null;

  // ✅ ONE notification per follower
  const ref = doc(
    db,
    "notifications",
    targetUid,
    "items",
    fromUid
  );

  await setDoc(
    ref,
    {
      type: "follow",
      fromUserId: fromUid,
      fromUserName: profile?.name || "Someone",
      fromUserAvatar: profile?.avatar || null,
      read: false,
      createdAt: serverTimestamp(),
    },
    { merge: true }
  );
}
