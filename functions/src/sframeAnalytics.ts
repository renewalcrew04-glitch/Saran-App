import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/services/firebase";

export async function getDailySFrameAnalytics(date: string) {
  const ref = doc(db, "sframeAnalytics", date);
  const snap = await getDoc(ref);

  if (!snap.exists()) return null;
  return snap.data();
}

admin.initializeApp();

export const aggregateDailySFrameAnalytics = onSchedule(
  "every day 00:05",
  async () => {
    const db = admin.firestore();

    const today = new Date();
    today.setDate(today.getDate() - 1);

    const dateKey = today.toISOString().split("T")[0];

    const start = admin.firestore.Timestamp.fromDate(
      new Date(`${dateKey}T00:00:00Z`)
    );
    const end = admin.firestore.Timestamp.fromDate(
      new Date(`${dateKey}T23:59:59Z`)
    );

    const snap = await db
      .collection("sframes")
      .where("createdAt", ">=", start)
      .where("createdAt", "<=", end)
      .get();

    let views = 0;
    let echoes = 0;

    snap.docs.forEach((doc) => {
      const data = doc.data();
      views += data.views?.length || 0;
      echoes += data.echoes?.length || 0;
    });

    await db.collection("sframeAnalytics").doc(dateKey).set({
      date: dateKey,
      views,
      echoes,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);
