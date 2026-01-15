import {
  View,
  Text,
  FlatList,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Image,
  Alert,
} from "react-native";
import VoiceWaveform from "@/components/chat/VoiceWaveform";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useEffect, useState } from "react";
import { Audio } from "expo-av";
import * as ImagePicker from "expo-image-picker";
import {
  collection,
  doc,
  getDoc,
  onSnapshot,
  orderBy,
  query,
} from "firebase/firestore";

import { auth, db } from "@/services/firebase";
import {
  sendMessage,
  markConversationRead,
  setTyping,
  clearTyping,
  reactToMessage,
} from "@/services/dm";

import { uploadImageAsync } from "@/utils/uploadImage";
import { formatPostTime } from "@/utils/formatPostTime";
import { Message, Reaction } from "@/types/message";
import FallbackAvatar from "@/components/ui/FallbackAvatar";
import { Ionicons } from "@expo/vector-icons";

/* ---------------- SCREEN ---------------- */

export default function Chat() {
  const { cid } = useLocalSearchParams<{ cid: string }>();
  const router = useRouter();
  const currentUid = auth.currentUser?.uid!;

  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState("");
  const [isTyping, setIsTyping] = useState(false);
  const [recording, setRecording] =
    useState<Audio.Recording | null>(null);

  const [otherUser, setOtherUser] = useState<{
    uid: string;
    name: string;
    avatar: string;
  } | null>(null);

  /* ---------------- LOAD CONVERSATION ---------------- */

  useEffect(() => {
    if (!cid) return;

    const ref = doc(db, "conversations", cid);

    getDoc(ref).then(async (snap) => {
      if (!snap.exists()) return;

      const participants = snap.data()
        .participants as string[];

      const otherUid =
        participants.find((p) => p !== currentUid) ??
        "";

      const profileSnap = await getDoc(
        doc(db, "profiles", otherUid)
      );

      if (profileSnap.exists()) {
        const p = profileSnap.data();
        setOtherUser({
          uid: otherUid,
          name: p.name ?? "User",
          avatar: p.avatar ?? "",
        });
      }
    });

    markConversationRead(cid, currentUid);
  }, [cid]);

  /* ---------------- LOAD MESSAGES ---------------- */

  useEffect(() => {
    if (!cid) return;

    const q = query(
      collection(db, "conversations", cid, "messages"),
      orderBy("createdAt", "asc")
    );

    return onSnapshot(q, (snap) => {
      setMessages(
        snap.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Omit<Message, "id">),
        }))
      );
    });
  }, [cid]);

  /* ---------------- TYPING LISTENER ---------------- */

  useEffect(() => {
    if (!cid || !otherUser) return;

    return onSnapshot(doc(db, "conversations", cid), (snap) => {
      const data = snap.data();
      if (!data?.typing) return;

      setIsTyping(data.typing[otherUser.uid] === true);
    });
  }, [cid, otherUser]);

  /* ---------------- SEND TEXT ---------------- */

  const sendTextMessage = async () => {
    if (!text.trim() || !cid || !otherUser) return;

    await sendMessage({
      conversationId: cid,
      senderUid: currentUid,
      receiverUid: otherUser.uid,
      text,
    });

    setText("");
    clearTyping(cid, currentUid);
  };

  /* ---------------- SEND IMAGE ---------------- */

  const sendImage = async () => {
  if (!cid || !otherUser) return;

  const res = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    quality: 0.7,
  });

  if (res.canceled) return;

  const imageUrl = await uploadImageAsync(
    res.assets[0].uri,
    "posts"
  );

  await sendMessage({
    conversationId: cid,
    senderUid: currentUid,
    receiverUid: otherUser.uid,
    text: imageUrl,
  });
};


  /* ---------------- VOICE RECORDING ---------------- */

  const startRecording = async () => {
    await Audio.requestPermissionsAsync();

    await Audio.setAudioModeAsync({
      allowsRecordingIOS: true,
      playsInSilentModeIOS: true,
    });

    const { recording } =
      await Audio.Recording.createAsync(
        Audio.RecordingOptionsPresets.HIGH_QUALITY
      );

    setRecording(recording);
  };

  const stopRecording = async () => {
    if (!recording || !cid || !otherUser) return;

    await recording.stopAndUnloadAsync();
    const uri = recording.getURI();
    setRecording(null);

    if (!uri) return;

    const voiceUrl = await uploadImageAsync(
      uri,
      "posts"
    );

    await sendMessage({
      conversationId: cid,
      senderUid: currentUid,
      receiverUid: otherUser.uid,
      text: voiceUrl,
    });
  };

  /* ---------------- REACTIONS ---------------- */

  const handleReaction = (
    messageId: string,
    reaction: Reaction
  ) => {
    if (!cid) return;
    reactToMessage(cid, messageId, currentUid, reaction);
  };

  /* ---------------- UI ---------------- */

  return (
    <View style={styles.container}>
      {/* HEADER */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={22} />
        </TouchableOpacity>

        {otherUser && (
          <>
            <FallbackAvatar
              uri={otherUser.avatar}
              size={36}
            />
            <Text style={styles.name}>
              {otherUser.name}
            </Text>
          </>
        )}
      </View>

      {/* MESSAGES */}
      <FlatList
        data={messages}
        keyExtractor={(i) => i.id}
        renderItem={({ item }) => {
          const isOwn =
            item.senderUid === currentUid;
            const text = item.text ?? "";

          return (
            <View
              style={[
                styles.bubbleWrap,
                isOwn ? styles.right : styles.left,
              ]}
            >
              <TouchableOpacity
                onLongPress={() =>
                  Alert.alert("React", "", [
                    {
                      text: "❤️",
                      onPress: () =>
                        handleReaction(item.id, "❤️"),
                    },
                    {
                      text: "😂",
                      onPress: () =>
                        handleReaction(item.id, "😂"),
                    },
                    {
                      text: "👍",
                      onPress: () =>
                        handleReaction(item.id, "👍"),
                    },
                    {
                      text: "😮",
                      onPress: () =>
                        handleReaction(item.id, "😮"),
                    },
                    { text: "Cancel", style: "cancel" },
                  ])
                }
                style={[
                  styles.bubble,
                  isOwn ? styles.own : styles.other,
                ]}
              >
                {/* MESSAGE CONTENT */}
{text.startsWith("[POST]::") ? (
  <TouchableOpacity
    onPress={() =>
      router.push({
        pathname: "/post/[id]",
        params: {
          id: text.replace("[POST]::", ""),
        },
      })
    }
    style={{
      padding: 12,
      borderRadius: 12,
      backgroundColor: isOwn ? "#222" : "#ddd",
    }}
  >
    <Text
      style={{
        color: isOwn ? "#fff" : "#000",
        fontWeight: "600",
      }}
    >
      📌 Shared a post
    </Text>
    <Text
      style={{
        fontSize: 12,
        marginTop: 4,
        color: isOwn ? "#aaa" : "#555",
      }}
    >
      Tap to view
    </Text>
  </TouchableOpacity>
) : item.type === "voice" ? (
  <VoiceWaveform
    uri={text}
    isOwn={isOwn}
  />
) : text.startsWith("http") ? (
  <Image
    source={{ uri: text }}
    style={styles.image}
  />
) : (
  <Text
    style={{
      color: isOwn ? "#fff" : "#000",
    }}
  >
    {text}
  </Text>
)}

              </TouchableOpacity>

              {item.reactions && (
                <View style={styles.reactions}>
                  {Object.values(item.reactions).map(
                    (r, i) => (
                      <Text key={i}>{r}</Text>
                    )
                  )}
                </View>
              )}

              <Text style={styles.time}>
                {formatPostTime(item.createdAt)}
              </Text>
            </View>
          );
        }}
      />

      {/* INPUT */}
      <View style={styles.inputRow}>
        <TouchableOpacity
          onPressIn={startRecording}
          onPressOut={stopRecording}
        >
          <Ionicons
            name={recording ? "mic" : "mic-outline"}
            size={24}
            color="#444"
          />
        </TouchableOpacity>

        <TouchableOpacity onPress={sendImage}>
          <Ionicons name="add" size={24} />
        </TouchableOpacity>

        <TextInput
          value={text}
          onChangeText={(t) => {
            setText(t);
            setTyping(cid!, currentUid, t.length > 0);
          }}
          onBlur={() =>
            clearTyping(cid!, currentUid)
          }
          placeholder="Type a message…"
          style={styles.input}
        />

        <TouchableOpacity onPress={sendTextMessage}>
          <Ionicons name="send" size={22} />
        </TouchableOpacity>
      </View>

      {isTyping && (
        <Text style={styles.typing}>Typing…</Text>
      )}
    </View>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#fff" },

  header: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    padding: 12,
    borderBottomWidth: 0.5,
    borderColor: "#eee",
  },

  name: { fontSize: 16, fontWeight: "600" },

  bubbleWrap: {
    marginVertical: 6,
    marginHorizontal: 10,
  },

  right: { alignItems: "flex-end" },
  left: { alignItems: "flex-start" },

  bubble: {
    padding: 12,
    borderRadius: 18,
    maxWidth: "75%",
  },

  own: { backgroundColor: "#000" },
  other: { backgroundColor: "#eee" },

  image: {
    width: 200,
    height: 200,
    borderRadius: 12,
  },

  reactions: {
    flexDirection: "row",
    gap: 6,
    marginTop: 4,
  },

  time: {
    fontSize: 11,
    color: "#888",
    marginTop: 4,
  },

  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    padding: 10,
    gap: 10,
    borderTopWidth: 0.5,
    borderColor: "#ddd",
  },

  input: {
    flex: 1,
    backgroundColor: "#f2f2f2",
    borderRadius: 18,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },

  typing: {
    paddingLeft: 16,
    paddingBottom: 6,
    color: "#666",
    fontSize: 12,
  },
});
