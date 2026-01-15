import { db } from "@/services/firebase";
import {
  doc,
  setDoc,
  updateDoc,
  serverTimestamp,
  getDoc,
} from "firebase/firestore";
import * as Location from "expo-location";

/* ---------------- CREATE / ACTIVATE SOS ---------------- */

export async function triggerSOS(
  uid: string,
  payload: {
    target: "friends" | "nearby";
    message?: string;
    location?: {
      lat: number;
      lng: number;
    };
  }
) {
  const ref = doc(db, "sos", uid);

  await setDoc(
    ref,
    {
      uid,
      active: true,
      target: payload.target,
      message: payload.message || "",
      location: payload.location || null,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    },
    { merge: true }
  );
}

/* ---------------- DEACTIVATE SOS ---------------- */

export async function resolveSOS(uid: string) {
  const ref = doc(db, "sos", uid);

  const snap = await getDoc(ref);
  if (!snap.exists()) return;

  await updateDoc(ref, {
    active: false,
    updatedAt: serverTimestamp(),
  });
}

export async function cancelSOS(uid: string) {
  await updateDoc(doc(db, "sos", uid), {
    active: false,
    resolvedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}