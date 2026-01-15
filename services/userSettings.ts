import { db } from "@/services/firebase";
import { doc, setDoc } from "firebase/firestore";

export async function updateUserSetting(
  uid: string,
  path: string,
  value: any
) {
  if (!uid) return;

  await setDoc(
    doc(db, "profiles", uid),
    {
      settings: buildNestedObject(path, value),
    },
    { merge: true }
  );
}

function buildNestedObject(path: string, value: any) {
  const keys = path.split(".");
  let obj: any = {};
  let current = obj;

  keys.forEach((k, i) => {
    if (i === keys.length - 1) {
      current[k] = value;
    } else {
      current[k] = {};
      current = current[k];
    }
  });

  return obj;
}
