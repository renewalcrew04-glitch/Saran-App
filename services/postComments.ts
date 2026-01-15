import { auth, db } from "@/services/firebase";
import {
  addDoc,
  collection,
  serverTimestamp,
} from "firebase/firestore";
import { notify } from "@/services/notify";

export async function addComment(
  postId: string,
  postOwnerId: string,
  text: string
) {
  const uid = auth.currentUser?.uid;
  if (!uid || !text.trim()) return;

  await addDoc(
    collection(db, "posts", postId, "comments"),
    {
      uid,
      text,
      createdAt: serverTimestamp(),
    }
  );

  await notify({
    userId: postOwnerId,
    fromUserId: uid,
    type: "comment",
    entityId: postId,
    entityType: "post",
    message: "commented on your post",
  });
}
