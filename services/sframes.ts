import {
  collection,
  getDocs,
  query,
  where,
  orderBy,
  Timestamp,
  onSnapshot,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";

/* ---------------- TYPES ---------------- */

export type SFrame = {
  id: string;
  uid: string;
  mediaType: "photo" | "video" | "text";
  mediaUrl?: string | null;
  textContent?: string | null;
  mood: string;
  expiresAt: Timestamp;
  createdAt: Timestamp;
  views?: string[];
  echoes?: string[];
};

/* ---------------- ONE-TIME FETCH ---------------- */

export async function fetchActiveSFrames() {
  if (!auth.currentUser) return [];

  const now = Timestamp.now();

  const q = query(
    collection(db, "sframes"),
    where("expiresAt", ">", now),
    orderBy("expiresAt", "asc")
  );

  const snap = await getDocs(q);

  return snap.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as Omit<SFrame, "id">),
  }));
}

/* ---------------- REAL-TIME ---------------- */

export function subscribeActiveSFrames(
  callback: (frames: SFrame[]) => void
) {
  if (!auth.currentUser) return () => {};

  const q = query(
    collection(db, "sframes"),
    where("expiresAt", ">", Timestamp.now()),
    orderBy("expiresAt", "asc")
  );

  return onSnapshot(q, (snap) => {
    callback(
      snap.docs.map((doc) => ({
        id: doc.id,
        ...(doc.data() as Omit<SFrame, "id">),
      }))
    );
  });
}
