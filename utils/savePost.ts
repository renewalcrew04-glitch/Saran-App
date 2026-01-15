import { doc, setDoc, deleteDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/services/firebase";

export const savePost = async (
  uid: string,
  postId: string
) => {
  if (!uid) return;

  await setDoc(doc(db, "profiles", uid, "saved", postId), {
    savedAt: serverTimestamp(),
  });
};

export const unsavePost = async (
  uid: string,
  postId: string
) => {
  if (!uid) return;

  await deleteDoc(doc(db, "profiles", uid, "saved", postId));
};
