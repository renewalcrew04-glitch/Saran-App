import { db } from "@/services/firebase";
import { doc, getDoc } from "firebase/firestore";

export async function resolveMentions(
  usernames: string[]
): Promise<string[]> {
  const uids: string[] = [];

  for (const username of usernames) {
    const ref = doc(db, "usernames", username);
    const snap = await getDoc(ref);

    if (snap.exists()) {
      uids.push(snap.data().uid);
    }
  }

  return uids;
}
