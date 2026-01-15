import {
  collection,
  getDocs,
  orderBy,
  query,
  startAt,
  endAt,
  where,
  limit,
  startAfter,
  QueryDocumentSnapshot,
} from "firebase/firestore";
import { db } from "@/services/firebase";
import type { Post } from "@/types/post";

/* 🔍 PEOPLE */
export async function searchPeople(text: string) {
  const q = query(
    collection(db, "profiles"),
    orderBy("nameLower"),
    startAt(text.toLowerCase()),
    endAt(text.toLowerCase() + "\uf8ff")
  );

  const snap = await getDocs(q);

  return snap.docs.map((d) => ({
    uid: d.id,
    ...d.data(),
  }));
}

/* 🔍 POSTS – PAGINATED */

export async function searchPostsPaginated({
  text,
  type,
  cursor,
  pageSize = 18,
}: {
  text: string;
  type?: "text" | "photo" | "video";
  cursor?: QueryDocumentSnapshot;
  pageSize?: number;
}) {
  const base = collection(db, "posts");

  const q = query(
    base,
    ...(type ? [where("type", "==", type)] : []),
    orderBy("text"),
    startAt(text),
    endAt(text + "\uf8ff"),
    ...(cursor ? [startAfter(cursor)] : []),
    limit(pageSize)
  );

  const snap = await getDocs(q);

  return {
    posts: snap.docs.map((d) => ({
      id: d.id,
      ...(d.data() as Omit<Post, "id">),
    })),
    cursor:
      snap.docs.length > 0
        ? snap.docs[snap.docs.length - 1]
        : undefined,
  };
}
