const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

/* 🔹 FORCE REGION */
setGlobalOptions({ region: "us-central1" });

exports.sendPushOnMessage = onDocumentCreated(
  "messages/{id}",
  async (event) => {
    const msg = event.data?.data();
    if (!msg) return;

    const receiverId = msg.receiverId;
    const senderId = msg.senderId;

    const userDoc = await admin
      .firestore()
      .doc(`profiles/${receiverId}`)
      .get();

    if (!userDoc.exists) return;

    const token = userDoc.data().expoPushToken;
    if (!token) return;

    await fetch("https://exp.host/--/api/v2/push/send", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        to: token,
        sound: "default",
        title: "New message",
        body: msg.text || "📩 New message",
        data: {
          type: "message",
          senderId,
        },
      }),
    });
  }
);
