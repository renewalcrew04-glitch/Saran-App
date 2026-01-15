import { db } from "@/services/firebase";
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  serverTimestamp,
  increment,
  collection,
  addDoc,
  query,
  where,
  getDocs,
  writeBatch,
  deleteField,
} from "firebase/firestore";

/* ADD / UPDATE MESSAGE REACTION */
export async function reactToMessage(
  conversationId: string,
  messageId: string,
  uid: string,
  reaction: "❤️" | "😂" | "👍" | "😮"
) {
  await setDoc(
    doc(
      db,
      "conversations",
      conversationId,
      "messages",
      messageId
    ),
    {
      reactions: {
        [uid]: reaction,
      },
    },
    { merge: true }
  );
}

/* MARK MESSAGES AS READ */
export async function markMessagesRead(
  conversationId: string,
  uid: string
) {
  const q = query(
    collection(
      db,
      "conversations",
      conversationId,
      "messages"
    ),
    where("receiverUid", "==", uid),
    where("read", "==", false)
  );

  const snap = await getDocs(q);
  const batch = writeBatch(db);

  snap.docs.forEach((d) => {
    batch.update(d.ref, { read: true });
  });

  await batch.commit();
}

/* TYPING STATUS */
export async function setTyping(
  conversationId: string,
  uid: string,
  value: boolean
) {
  await updateDoc(doc(db, "conversations", conversationId), {
    [`typing.${uid}`]: value,
  });
}

export async function clearTyping(
  conversationId: string,
  uid: string
) {
  await updateDoc(doc(db, "conversations", conversationId), {
    [`typing.${uid}`]: deleteField(),
  });
}

/* MUTE / ARCHIVE */
export async function muteConversation(
  conversationId: string,
  uid: string,
  value: boolean
) {
  await updateDoc(doc(db, "conversations", conversationId), {
    [`muted.${uid}`]: value,
  });
}

export async function archiveConversation(
  conversationId: string,
  uid: string,
  value: boolean
) {
  await updateDoc(doc(db, "conversations", conversationId), {
    [`archived.${uid}`]: value,
  });
}

/* CREATE OR GET CONVERSATION */
export async function getOrCreateConversation(
  currentUid: string,
  otherUid: string
) {
  const conversationId =
    currentUid < otherUid
      ? `${currentUid}_${otherUid}`
      : `${otherUid}_${currentUid}`;

  const ref = doc(db, "conversations", conversationId);
  const snap = await getDoc(ref);

  if (!snap.exists()) {
    await setDoc(ref, {
      participants: [currentUid, otherUid],
      unread: {
        [currentUid]: 0,
        [otherUid]: 0,
      },
      lastMessage: "",
      lastMessageType: "text",
      lastMessageAt: serverTimestamp(),
      createdAt: serverTimestamp(),
    });
  }

  return conversationId;
}

/* SEND MESSAGE */
export async function sendMessage({
  conversationId,
  senderUid,
  receiverUid,
  text,
}: {
  conversationId: string;
  senderUid: string;
  receiverUid: string;
  text: string;
}) {
  await addDoc(
    collection(
      db,
      "conversations",
      conversationId,
      "messages"
    ),
    {
      senderUid,
      receiverUid,
      text,
      type: "text",
      read: false,
      createdAt: serverTimestamp(),
    }
  );

  await setDoc(
    doc(
      db,
      "notifications",
      receiverUid,
      "items",
      `${conversationId}_${Date.now()}`
    ),
    {
      fromUserId: senderUid,
      type: "dm",
      entityType: "conversation",
      entityId: conversationId,
      read: false,
      createdAt: serverTimestamp(),
    }
  );

  await updateDoc(doc(db, "conversations", conversationId), {
    [`unread.${receiverUid}`]: increment(1),
    lastMessage: text,
    lastMessageType: "text",
    lastMessageAt: serverTimestamp(),
  });
}

/* MARK CONVERSATION READ */
export async function markConversationRead(
  conversationId: string,
  uid: string
) {
  await updateDoc(doc(db, "conversations", conversationId), {
    [`unread.${uid}`]: 0,
  });
}
