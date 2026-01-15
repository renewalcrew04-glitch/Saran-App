import { auth, db } from "@/services/firebase";
import {
  collection,
  doc,
  setDoc,
  deleteDoc,
  serverTimestamp,
  query,
  orderBy,
  onSnapshot,
} from "firebase/firestore";

export type TimelineItem = {
  id: string;
  type: "post" | "repost" | "quote";
  postId: string;
  actorUid: string;
  createdAt?: any;
};

function timelineCol(uid: string) {
  return collection(db, "profiles", uid, "timeline");
}

/* ===========================
   ADD ITEMS
=========================== */

export async function addTimelineItem({
  type,
  postId,
}: {
  type: "post" | "repost" | "quote";
  postId: string;
}) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  // unique id to prevent duplicates
  const itemId = `${type}_${postId}_${uid}`;

  await setDoc(doc(db, "profiles", uid, "timeline", itemId), {
    type,
    postId,
    actorUid: uid,
    createdAt: serverTimestamp(),
  });
}

export async function removeTimelineItem({
  type,
  postId,
}: {
  type: "post" | "repost" | "quote";
  postId: string;
}) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  const itemId = `${type}_${postId}_${uid}`;
  await deleteDoc(doc(db, "profiles", uid, "timeline", itemId));
}

/* ===========================
   SUBSCRIBE TIMELINE
=========================== */

export function subscribeMyTimeline(
  callback: (items: TimelineItem[]) => void
) {
  const uid = auth.currentUser?.uid;
  if (!uid) return () => {};

  const q = query(timelineCol(uid), orderBy("createdAt", "desc"));

  return onSnapshot(q, (snap) => {
    const items: TimelineItem[] = snap.docs.map((d) => ({
      id: d.id,
      ...(d.data() as any),
    }));
    callback(items);
  });
}
