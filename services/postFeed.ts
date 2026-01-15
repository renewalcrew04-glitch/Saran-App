import { db } from "@/services/firebase";
import {
  collection,
  query,
  orderBy,
  limit,
  getDocs,
  Timestamp,
} from "firebase/firestore";
import { Post } from "@/types/post";

export async function fetchHomeFeed(): Promise<Post[]> {
  const q = query(
    collection(db, "posts"),
    orderBy("createdAt", "desc"),
    limit(30)
  );

  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();

    return {
      id: doc.id,
      uid: data.uid,
      username: data.username ?? "",
      type: data.type as Post["type"],

      text: data.text ?? "",
      media: data.media ?? [],

      createdAt: data.createdAt as Timestamp,
    };
  });
}
