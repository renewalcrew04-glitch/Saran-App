import { collection, getCountFromServer } from "firebase/firestore";
import { db } from "@/services/firebase";

export async function getFollowersCount(uid: string) {
  const snap = await getCountFromServer(
    collection(db, "follows", uid, "followers")
  );
  return snap.data().count;
}

export async function getFollowingCount(uid: string) {
  const snap = await getCountFromServer(
    collection(db, "follows", uid, "following")
  );
  return snap.data().count;
}
