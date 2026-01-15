import { doc, getDoc } from "firebase/firestore";
import { db } from "@/services/firebase";

export async function fetchProfile(uid: string) {
  const snap = await getDoc(doc(db, "profiles", uid));
  if (!snap.exists()) return null;

  return {
    uid,
    ...snap.data(),
  };
}

const profileCache = new Map<string, any>();

export async function getProfileLite(uid: string) {
  if (profileCache.has(uid)) {
    return profileCache.get(uid);
  }

  const snap = await getDoc(doc(db, "profiles", uid));
  if (!snap.exists()) return null;

  const data = snap.data();

  const lite = {
    uid,
    name: data.name,
    avatar: data.avatar || null,
  };

  profileCache.set(uid, lite);
  return lite;
}
