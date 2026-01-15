import { db } from "@/services/firebase";
import {
  addDoc,
  collection,
  serverTimestamp,
} from "firebase/firestore";

type NotifyParams = {
  userId: string;
  fromUserId: string;
  type: string;
  entityId: string;
  entityType: "post" | "comment" | "sframe";
  message: string;
};

export async function notify({
  userId,
  fromUserId,
  type,
  entityId,
  entityType,
  message,
}: NotifyParams) {
  if (userId === fromUserId) return;

  await addDoc(
    collection(db, "notifications", userId, "items"),
    {
      fromUserId,
      type,
      entityId,
      entityType,
      message,
      read: false,
      createdAt: serverTimestamp(),
    }
  );
}
