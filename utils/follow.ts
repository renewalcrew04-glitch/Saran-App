import {
  doc,
  getDoc,
  setDoc,
  deleteDoc,
  serverTimestamp,
} from "firebase/firestore";
import { auth, db } from "@/services/firebase";
import { notifyFollow } from "@/services/followNotifications";
import {
  getFollowersCount,
  getFollowingCount,
} from "@/services/followCounts";

/* ---------------------------------------------------
   INTERNAL HELPER
--------------------------------------------------- */
function resolveCurrentUid(explicitUid?: string) {
  return explicitUid ?? auth.currentUser?.uid;
}

/* ---------------------------------------------------
   FOLLOW USER
   ✅ Supports:
   - followUser(targetUid)
   - followUser(currentUid, targetUid)
--------------------------------------------------- */
export async function followUser(
  arg1?: string,
  arg2?: string
) {
  const currentUid = arg2 ? arg1 : resolveCurrentUid();
  const targetUid = arg2 ?? arg1;

  if (!currentUid) {
    console.warn("followUser: currentUid missing");
    return;
  }

  if (!targetUid) {
    console.warn("followUser: targetUid missing");
    return;
  }

  if (currentUid === targetUid) return;

  await setDoc(
    doc(db, "follows", currentUid, "following", targetUid),
    { createdAt: serverTimestamp() }
  );

  await setDoc(
    doc(db, "follows", targetUid, "followers", currentUid),
    { createdAt: serverTimestamp() }
  );

  await notifyFollow(targetUid);

  // keep existing count refresh behavior
  await Promise.all([
    getFollowersCount(targetUid),
    getFollowingCount(currentUid),
  ]);
}

/* ---------------------------------------------------
   UNFOLLOW USER
   ✅ Supports:
   - unfollowUser(targetUid)
   - unfollowUser(currentUid, targetUid)
--------------------------------------------------- */
export async function unfollowUser(
  arg1?: string,
  arg2?: string
) {
  const currentUid = arg2 ? arg1 : resolveCurrentUid();
  const targetUid = arg2 ?? arg1;

  if (!currentUid || !targetUid) return;

  await deleteDoc(
    doc(db, "follows", currentUid, "following", targetUid)
  );

  await deleteDoc(
    doc(db, "follows", targetUid, "followers", currentUid)
  );

  await Promise.all([
    getFollowersCount(targetUid),
    getFollowingCount(currentUid),
  ]);
}

/* ---------------------------------------------------
   CHECK IF FOLLOWING
   ✅ Supports:
   - checkIfFollowing(targetUid)
   - checkIfFollowing(currentUid, targetUid)
--------------------------------------------------- */
export async function checkIfFollowing(
  arg1?: string,
  arg2?: string
): Promise<boolean> {
  const currentUid = arg2 ? arg1 : resolveCurrentUid();
  const targetUid = arg2 ?? arg1;

  if (!currentUid || !targetUid) return false;

  const snap = await getDoc(
    doc(db, "follows", currentUid, "following", targetUid)
  );

  return snap.exists();
}
