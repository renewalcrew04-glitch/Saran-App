import {
  View,
  Text,
  FlatList,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  SafeAreaView,
} from "react-native";
import { useEffect, useState } from "react";
import {
  collection,
  addDoc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  doc,
  setDoc,
  deleteDoc,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";
import { Ionicons } from "@expo/vector-icons";
import { formatPostTime } from "@/utils/formatPostTime";
import { getProfileLite } from "@/services/profileLookup";
import { useSafeAreaInsets } from "react-native-safe-area-context";

type Comment = {
  id: string;
  uid: string;
  text: string;
  createdAt: Timestamp;
  parentId?: string | null;
  user?: { name?: string };
};

export default function PostComments({ postId }: { postId: string }) {
  const uid = auth.currentUser?.uid!;
  const insets = useSafeAreaInsets();

  const [text, setText] = useState("");
  const [comments, setComments] = useState<Comment[]>([]);
  const [replyTo, setReplyTo] = useState<Comment | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, "posts", postId, "comments"),
      orderBy("createdAt", "asc")
    );

    return onSnapshot(q, async (snap) => {
      const resolved = await Promise.all(
  snap.docs.map(async (d) => {
    const data = d.data() as Omit<Comment, "id">;
    const profile = await getProfileLite(data.uid);

    return {
      id: d.id,
      uid: data.uid,
      text: data.text,
      createdAt: data.createdAt,
      parentId: data.parentId ?? null,
      user: profile ?? undefined,
    };
  })
);

      setComments(resolved);
    });
  }, [postId]);

  const send = async () => {
    if (!uid || !text.trim()) return;

    await addDoc(collection(db, "posts", postId, "comments"), {
      uid,
      text,
      parentId: replyTo ? replyTo.id : null,
      createdAt: serverTimestamp(),
    });

    setText("");
    setReplyTo(null);
  };

  const rootComments = comments.filter((c) => !c.parentId);
  const replies = (id: string) =>
    comments.filter((c) => c.parentId === id);

  return (
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        keyboardVerticalOffset={insets.top + 56}
      >
        {/* HEADER */}
        <View style={[styles.header, { paddingTop: insets.top }]}>
          <Text style={styles.headerTitle}>Comments</Text>
        </View>

        {/* LIST */}
        <FlatList
          data={rootComments}
          keyExtractor={(i) => i.id}
          contentContainerStyle={{
            paddingBottom: 120 + insets.bottom,
          }}
          renderItem={({ item }) => (
            <View>
              <CommentRow
                postId={postId}
                comment={item}
                onReply={() => setReplyTo(item)}
              />

              {replies(item.id).map((r) => (
                <View key={r.id} style={styles.replyIndent}>
                  <CommentRow
                    postId={postId}
                    comment={r}
                    isReply
                  />
                </View>
              ))}
            </View>
          )}
        />

        {/* REPLY BANNER */}
        {replyTo && (
          <View style={styles.replyBanner}>
            <Text style={styles.replyText}>
              Replying to {replyTo.user?.name}
            </Text>
            <TouchableOpacity onPress={() => setReplyTo(null)}>
              <Ionicons name="close" size={16} color="#fff" />
            </TouchableOpacity>
          </View>
        )}

        {/* INPUT */}
        <View
          style={[
            styles.inputBar,
            { paddingBottom: insets.bottom },
          ]}
        >
          <TextInput
            placeholder="Add a comment…"
            placeholderTextColor="#888"
            value={text}
            onChangeText={setText}
            style={styles.input}
          />

          <TouchableOpacity
            onPress={send}
            disabled={!text.trim()}
          >
            <Ionicons
              name="paper-plane"
              size={22}
              color={text.trim() ? "#4da3ff" : "#555"}
            />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

/* ---------------- COMMENT ROW ---------------- */

function CommentRow({
  postId,
  comment,
  onReply,
  isReply,
}: {
  postId: string;
  comment: Comment;
  onReply?: () => void;
  isReply?: boolean;
}) {
  const uid = auth.currentUser?.uid!;
  const [liked, setLiked] = useState(false);
  const [likes, setLikes] = useState(0);

  useEffect(() => {
    const ref = collection(
      db,
      "posts",
      postId,
      "comments",
      comment.id,
      "likes"
    );

    return onSnapshot(ref, (snap) => {
      setLikes(snap.size);
      setLiked(snap.docs.some((d) => d.id === uid));
    });
  }, []);

  const toggleLike = async () => {
    const ref = doc(
      db,
      "posts",
      postId,
      "comments",
      comment.id,
      "likes",
      uid
    );

    liked ? await deleteDoc(ref) : await setDoc(ref, { uid });
  };

  return (
    <View style={styles.commentRow}>
      <View style={styles.avatar} />

      <View style={styles.body}>
        <Text style={styles.name}>
          {comment.user?.name || "Unknown"}
        </Text>

        <Text style={styles.text}>{comment.text}</Text>

        <View style={styles.meta}>
          <Text style={styles.time}>
            {formatPostTime(comment.createdAt)}
          </Text>

          {!isReply && onReply && (
            <TouchableOpacity onPress={onReply}>
              <Text style={styles.reply}>Reply</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* LIKE */}
      <TouchableOpacity onPress={toggleLike} style={styles.likeBox}>
        <Ionicons
          name={liked ? "heart" : "heart-outline"}
          size={16}
          color={liked ? "red" : "#888"}
        />
        {likes > 0 && (
          <Text style={styles.likeCount}>{likes}</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#000" },

  header: {
    paddingVertical: 10,
    alignItems: "center",
    borderBottomWidth: 1,
    borderColor: "#222",
  },
  headerTitle: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "600",
  },

  commentRow: {
    flexDirection: "row",
    padding: 12,
  },
  replyIndent: {
    marginLeft: 44,
  },
  avatar: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: "#333",
    marginRight: 10,
  },
  body: { flex: 1 },
  name: { color: "#fff", fontWeight: "600", fontSize: 13 },
  text: { color: "#eee", fontSize: 14, marginVertical: 4 },
  meta: { flexDirection: "row", gap: 14 },
  time: { fontSize: 11, color: "#777" },
  reply: { fontSize: 11, color: "#777" },

  likeBox: {
    alignItems: "center",
    justifyContent: "center",
    width: 28,
  },
  likeCount: {
    fontSize: 10,
    color: "#aaa",
    marginTop: 2,
  },

  replyBanner: {
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: "#111",
    borderTopWidth: 1,
    borderColor: "#222",
  },
  replyText: { color: "#aaa", fontSize: 12 },

  inputBar: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingTop: 10,
    borderTopWidth: 1,
    borderColor: "#222",
    backgroundColor: "#000",
    gap: 10,
  },
  input: {
    flex: 1,
    backgroundColor: "#111",
    color: "#fff",
    borderRadius: 20,
    paddingHorizontal: 14,
    height: 40,
  },
});
