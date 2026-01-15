import { db, auth } from "@/services/firebase";
import {
  doc,
  setDoc,
  deleteDoc,
  getDoc,
  serverTimestamp,
} from "firebase/firestore";
import { notify } from "@/services/notify";

export async function likePost(postId: string, postOwnerId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  await setDoc(doc(db, "posts", postId, "likes", uid), {
    uid,
    createdAt: serverTimestamp(),
  });

  await notify({
    userId: postOwnerId,
    fromUserId: uid,
    type: "like",
    entityId: postId,
    entityType: "post",
    message: "liked your post",
  });
}

export async function unlikePost(postId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  await deleteDoc(doc(db, "posts", postId, "likes", uid));
}

export async function hasLiked(postId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return false;

  const snap = await getDoc(
    doc(db, "posts", postId, "likes", uid)
  );
  return snap.exists();
}
