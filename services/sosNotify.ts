import {
  collection,
  getDocs,
  doc,
  setDoc,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/services/firebase";

export async function notifyCloseFriends(
  uid: string,
  sosId: string
) {
  const snap = await getDocs(
    collection(db, "profiles", uid, "closeFriends")
  );

  const batch: Promise<any>[] = [];

  snap.forEach((d) => {
    const friendUid = d.id;

    batch.push(
      setDoc(
        doc(
          db,
          "notifications",
          friendUid,
          "items",
          `sos_${uid}_${Date.now()}`
        ),
        {
          fromUserId: uid,
          type: "sos",
          entityType: "sos",
          entityId: sosId,
          read: false,
          createdAt: serverTimestamp(),
        }
      )
    );
  });

  await Promise.all(batch);
}
