import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { QueryDocumentSnapshot } from "firebase-admin/firestore";

admin.initializeApp();

export const deleteExpiredSFrames = onSchedule(
  "every 1 hours",
  async () => {
    const now = admin.firestore.Timestamp.now();

    const snap = await admin
      .firestore()
      .collection("sframes")
      .where("expiresAt", "<=", now)
      .get();

    const batch = admin.firestore().batch();

    snap.docs.forEach((doc: QueryDocumentSnapshot) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
  }
);
