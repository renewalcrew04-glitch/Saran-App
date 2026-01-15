import { db, auth } from "@/services/firebase";
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  setDoc,
} from "firebase/firestore";

type RelationType = "blocked" | "muted" | "closeFriends";

export async function getUserList(type: RelationType) {
  const uid = auth.currentUser?.uid;
  if (!uid) return [];

  const snap = await getDocs(collection(db, type, uid, "users"));
  return snap.docs.map((d) => d.id);
}

export async function addUser(type: RelationType, targetUid: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  await setDoc(doc(db, type, uid, "users", targetUid), {
    createdAt: Date.now(),
  });
}

export async function removeUser(type: RelationType, targetUid: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  await deleteDoc(doc(db, type, uid, "users", targetUid));
}
