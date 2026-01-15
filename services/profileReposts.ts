import {
  collectionGroup,
  getDocs,
  query,
  where,
  doc,
  getDoc,
  onSnapshot,
  orderBy,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";
import type { Post } from "@/types/post";

// ✅ existing one-time fetch (keep as it is)
export async function fetchUserReposts(uid: string): Promise<Post[]> {
  const repostQ = query(
    collectionGroup(db, "reposts"),
    where("uid", "==", uid)
  );

  const repostSnap = await getDocs(repostQ);

  const postIds = repostSnap.docs
    .map((d) => d.ref.parent.parent?.id)
    .filter(Boolean) as string[];

  const posts: Post[] = [];

  for (const postId of postIds) {
    const postSnap = await getDoc(doc(db, "posts", postId));
    if (postSnap.exists()) {
      posts.push({
        id: postSnap.id,
        ...(postSnap.data() as any),
        type: "repost",
      });
    }
  }

  return posts;
}

/* =====================================================
   ✅ REALTIME LISTENER (NEW)
===================================================== */

export function listenToUserReposts(
  uid: string | undefined,
  callback: (posts: Post[]) => void
) {
  if (!uid || !auth.currentUser) return () => {};

  const repostQ = query(
    collectionGroup(db, "reposts"),
    where("uid", "==", uid),
    orderBy("createdAt", "desc")
  );

  const unsub = onSnapshot(
    repostQ,
    async (snap) => {
      try {
        const postIds = snap.docs
          .map((d) => d.ref.parent.parent?.id)
          .filter(Boolean) as string[];

        const posts: Post[] = [];

        for (const postId of postIds) {
          const postSnap = await getDoc(doc(db, "posts", postId));
          if (postSnap.exists()) {
            posts.push({
              id: postSnap.id,
              ...(postSnap.data() as any),
              type: "repost",
              repostedByUid: uid,
            } as any);
          }
        }

        callback(posts);
      } catch (e) {
        console.log("listenToUserReposts error:", e);
        callback([]);
      }
    },
    (err) => {
      console.log("listenToUserReposts snapshot error:", err);
      callback([]);
    }
  );

  return () => unsub();
}
