import { db, auth } from "@/services/firebase";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { notify } from "@/services/notify";

export async function sharePost(postId: string, postOwnerId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  await setDoc(doc(db, "posts", postId, "shares", uid), {
    uid,
    createdAt: serverTimestamp(),
  });

  if (postOwnerId !== uid) {
    await notify({
      userId: postOwnerId,
      fromUserId: uid,
      type: "share",
      entityId: postId,
      entityType: "post",
      message: "shared your post",
    });
  }
}
