import * as Contacts from "expo-contacts";

export type PhoneContact = {
  name: string;
  phone: string;
};

export async function getDeviceContacts(): Promise<PhoneContact[]> {
  const { status } = await Contacts.requestPermissionsAsync();

  if (status !== "granted") {
    return [];
  }

  const { data } = await Contacts.getContactsAsync({
    fields: [Contacts.Fields.PhoneNumbers],
  });

  if (!data.length) return [];

  const contacts: PhoneContact[] = [];

  data.forEach((c) => {
    if (c.phoneNumbers && c.phoneNumbers.length > 0) {
      c.phoneNumbers.forEach((p) => {
        contacts.push({
          name: c.name || "Unknown",
          phone: normalizePhone(p.number),
        });
      });
    }
  });

  return contacts;
}

function normalizePhone(phone?: string) {
  if (!phone) return "";
  return phone.replace(/[^0-9+]/g, "");
}
import { collection, doc, setDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/services/firebase";

export async function saveContactsToFirestore(
  uid: string,
  contacts: PhoneContact[]
) {
  const ref = collection(db, "profiles", uid, "contacts");

  for (const c of contacts) {
    if (!c.phone) continue;

    await setDoc(
      doc(ref),
      {
        phone: c.phone,
        name: c.name,
        createdAt: serverTimestamp(),
      },
      { merge: true }
    );
  }
}
import { getDocs } from "firebase/firestore";

export async function getSavedContacts(uid: string): Promise<Set<string>> {
  const snap = await getDocs(
    collection(db, "profiles", uid, "contacts")
  );

  const phones = new Set<string>();

  snap.docs.forEach((d) => {
    const phone = d.data().phone;
    if (phone) {
      phones.add(phone);
    }
  });

  return phones;
}
