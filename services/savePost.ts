import { db, auth } from "@/services/firebase";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { notify } from "@/services/notify";

export async function savePost(postId: string, postOwnerId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  await setDoc(doc(db, "profiles", uid, "saved", postId), {
    uid,
    createdAt: serverTimestamp(),
  });

  if (postOwnerId !== uid) {
    await notify({
      userId: postOwnerId,
      fromUserId: uid,
      type: "save",
      entityId: postId,
      entityType: "post",
      message: "saved your post",
    });
  }
}
