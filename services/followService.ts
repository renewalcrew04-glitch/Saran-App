import {
  collection,
  getDocs,
  query,
  orderBy,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";
import { doc, setDoc, serverTimestamp, deleteDoc } from "firebase/firestore";

/* ---------------------------------------
   GET USERS YOU FOLLOW
---------------------------------------- */

export async function getFollowing(uid: string) {
  const q = query(
    collection(db, "follows", uid, "following"),
    orderBy("createdAt", "desc")
  );

  const snap = await getDocs(q);

  return snap.docs.map((doc) => ({
    uid: doc.id,
    ...doc.data(),
  }));
}

export async function followUser(targetUid: string) {
  const myUid = auth.currentUser?.uid;
  if (!myUid) return;

  // 1) add to my following
  await setDoc(doc(db, "follows", myUid, "following", targetUid), {
    createdAt: serverTimestamp(),
  });

  // 2) add to their followers
  await setDoc(doc(db, "follows", targetUid, "followers", myUid), {
    createdAt: serverTimestamp(),
  });
}

export async function unfollowUser(targetUid: string) {
  const myUid = auth.currentUser?.uid;
  if (!myUid) return;

  // remove from my following
  await deleteDoc(doc(db, "follows", myUid, "following", targetUid));

  // remove from their followers
  await deleteDoc(doc(db, "follows", targetUid, "followers", myUid));
}
