import { db, auth } from "@/services/firebase";
import {
  doc,
  getDoc,
  setDoc,
  deleteDoc,
  updateDoc,
  increment,
  serverTimestamp
} from "firebase/firestore";
export async function toggleRepost(postId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Not logged in");

  const repostRef = doc(db, "posts", postId, "reposts", uid);
  const postRef = doc(db, "posts", postId);

  const snap = await getDoc(repostRef);

  // if already reposted -> remove repost
  if (snap.exists()) {
    await deleteDoc(repostRef);
    await updateDoc(postRef, {
      repostsCount: increment(-1),
    });
    return { reposted: false };
  }

await setDoc(repostRef, {
  uid,                 // ✅ required for collectionGroup query
  createdAt: serverTimestamp(),
});

  await updateDoc(postRef, {
    repostsCount: increment(1),
  });

  return { reposted: true };
}

export async function checkIfReposted(postId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return false;

  const repostRef = doc(db, "posts", postId, "reposts", uid);
  const snap = await getDoc(repostRef);
  return snap.exists();
}
