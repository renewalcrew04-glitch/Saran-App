import { db, auth } from "@/services/firebase";
import { collection, getDocs } from "firebase/firestore";

export async function getNonMutualSuggestions() {
  const uid = auth.currentUser?.uid;
  if (!uid) return [];

  const followingSnap = await getDocs(
    collection(db, "follows", uid, "following")
  );
  const followersSnap = await getDocs(
    collection(db, "follows", uid, "followers")
  );

  const following = new Set(followingSnap.docs.map(d => d.id));
  const followers = new Set(followersSnap.docs.map(d => d.id));

  return Array.from(followers)
    .filter((u) => !following.has(u))
    .map((uid) => ({ uid }));
}
