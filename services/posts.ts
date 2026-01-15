import {
  collection,
  getDocs,
  orderBy,
  query,
  where,
  onSnapshot,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";

/* ---------------- TYPES ---------------- */

export type Post = {
  id: string;
  uid: string;
  type: "text" | "photo" | "video" | "repost";
  text?: string;
  media?: string[];
  createdAt: any;
};

/* ---------------- ONE-TIME FETCH ---------------- */

export async function fetchUserPosts(uid?: string): Promise<Post[]> {
  if (!uid || !auth.currentUser) return [];

  const q = query(
    collection(db, "posts"),
    where("uid", "==", uid),
    orderBy("createdAt", "desc")
  );

  const snap = await getDocs(q);

  return snap.docs.map((d) => ({
    id: d.id,
    ...(d.data() as Omit<Post, "id">),
  }));
}

/* ---------------- REAL-TIME LISTENER ---------------- */

export function listenToUserPosts(
  uid: string | undefined,
  callback: (posts: Post[]) => void
) {
  if (!uid || !auth.currentUser) return () => {};

  const q = query(
    collection(db, "posts"),
    where("uid", "==", uid),
    orderBy("createdAt", "desc")
  );

  return onSnapshot(q, (snap) => {
    callback(
      snap.docs.map((d) => ({
        id: d.id,
        ...(d.data() as Omit<Post, "id">),
      }))
    );
  });
}
