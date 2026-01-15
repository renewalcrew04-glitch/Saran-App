import {
  View,
  Text,
  StyleSheet,
  Image,
  TouchableOpacity,
  Dimensions,
  PanResponder,
  Animated,
  Pressable,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  FlatList,
  Modal,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Video } from "expo-av";
import { useAuthReady } from "@/hooks/useAuthReady";
import { useEffect, useRef, useState } from "react";
import { useLocalSearchParams, useRouter } from "expo-router";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  updateDoc,
  arrayUnion,
  addDoc,
  query,
  where,
  Timestamp,
} from "firebase/firestore";
import Screen from "@components/Screen";
import { db } from "@/services/firebase";
import { Colors } from "@constants/colors";
import { formatPostTime } from "@/utils/formatPostTime";
import { ResizeMode } from "expo-av";

const { width, height } = Dimensions.get("window");
const DAY = 24 * 60 * 60 * 1000;
const FRAME_DURATION = 5000;

/* ---------------- TYPES ---------------- */

type SFrameItem = {
  id: string;
  uid: string;
  mediaType: "image" | "video" | "text";
  mediaUrl?: string;
  textContent?: string;
  mood?: string;
  createdAt: Timestamp;
  views?: string[];
};

type ProfileLite = {
  name: string;
  photoURL: string;
};

export default function ViewSFrame() {
  const { id: userId, order } = useLocalSearchParams<{ id: string; order?: string }>();
const userOrder = order ? order.split(",") : [];
const userIndex = userOrder.indexOf(userId);
  const router = useRouter();
  const user = useAuthReady();
  const uid = user?.uid ?? null;

  const [frames, setFrames] = useState<SFrameItem[]>([]);
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const [reply, setReply] = useState("");

  const [profile, setProfile] = useState<ProfileLite | null>(null);
  const [showSeen, setShowSeen] = useState(false);
  const [seenUsers, setSeenUsers] = useState<ProfileLite[]>([]);

  const progressAnim = useRef(new Animated.Value(0)).current;
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const remainingRef = useRef(FRAME_DURATION);

  const frame = frames[index];
  const goToNextUser = () => {
  const nextUid = userOrder[userIndex + 1];

  if (nextUid) {
    router.replace({
      pathname: "/sframe/view/[id]",
      params: {
        id: nextUid,
        order,
      },
    });
  } else {
    router.back(); // only exit after LAST user
  }
};

const goToPrevUser = () => {
  const prevUid = userOrder[userIndex - 1];

  if (prevUid) {
    router.replace({
      pathname: "/sframe/view/[id]",
      params: {
        id: prevUid,
        order,
      },
    });
  }
};

  /* ---------------- FOLLOWER CHECK ---------------- */

  const checkFollowerAccess = async () => {
    if (!uid || !userId) return false;
    if (uid === userId) return true;

    const snap = await getDoc(
      doc(db, "followers", userId, "list", uid)
    );
    return snap.exists();
  };

  /* ---------------- LOAD FRAMES ---------------- */

  useEffect(() => {
    if (!uid || !userId) return;

    const load = async () => {
      const allowed = await checkFollowerAccess();
      if (!allowed) {
        setFrames([]);
        return;
      }

      const q = query(
        collection(db, "sframes"),
        where("uid", "==", userId)
      );

      const snap = await getDocs(q);
      const now = Date.now();

      const list: SFrameItem[] = snap.docs
        .map((d) => ({
          id: d.id,
          ...(d.data() as Omit<SFrameItem, "id">),
        }))
        .filter(
          (f) =>
            f.createdAt &&
            now - f.createdAt.toMillis() <= DAY
        )
        .sort(
          (a, b) =>
            a.createdAt.toMillis() -
            b.createdAt.toMillis()
        );

      setFrames(list);
      setIndex(0);
    };

    load();
  }, [userId, uid]);

  /* ---------------- LOAD PROFILE ---------------- */

  useEffect(() => {
    if (!userId) return;

    getDoc(doc(db, "profiles", userId)).then((snap) => {
      if (snap.exists()) {
        const d = snap.data();
        setProfile({
          name: d.name,
          photoURL: d.photoURL,
        });
      }
    });
  }, [userId]);

  /* ---------------- VIEW TRACK ---------------- */

  useEffect(() => {
    if (!frame || !uid) return;

    updateDoc(doc(db, "sframes", frame.id), {
      views: arrayUnion(uid),
    });
  }, [frame?.id, uid]);

  /* ---------------- TIMER ---------------- */

  const startTimer = (duration: number) => {
    progressAnim.setValue(0);

    Animated.timing(progressAnim, {
      toValue: 1,
      duration,
      useNativeDriver: false,
    }).start();

    timerRef.current = setTimeout(() => {
  if (index < frames.length - 1) {
    setIndex((i) => i + 1);
  } else {
    goToNextUser();
  }
}, duration);
  };

  useEffect(() => {
    if (!frame || paused) return;

    startTimer(FRAME_DURATION);

    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [index, frame, paused]);

  /* ---------------- PRESS & HOLD ---------------- */

  const onHold = () => {
    setPaused(true);
    progressAnim.stopAnimation((v) => {
      remainingRef.current = FRAME_DURATION * (1 - v);
    });
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
  };

  const onRelease = () => {
    setPaused(false);
    startTimer(remainingRef.current);
  };

  /* ---------------- TAP NAV ---------------- */

  const onTap = (e: any) => {
    const x = e.nativeEvent.locationX;
    if (x > width / 2) {
  if (index < frames.length - 1) {
    setIndex((i) => i + 1);
  } else {
    goToNextUser();
  }
} else {
  if (index > 0) {
    setIndex((i) => i - 1);
  } else {
    goToPrevUser();
  }
}
  };

  /* ---------------- SWIPE ---------------- */

  const pan = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, g) =>
        Math.abs(g.dx) > 20,
      onPanResponderRelease: (_, g) => {
        if (g.dx < -50) {
  goToNextUser();
}
if (g.dx > 50) {
  goToPrevUser();
}
      },
    })
  ).current;

  /* ---------------- REPLY ---------------- */

  const sendReply = async () => {
    if (!uid || !frame || !reply.trim()) return;

    await addDoc(collection(db, "sframeReplies"), {
      frameId: frame.id,
      fromUid: uid,
      toUid: frame.uid,
      text: reply.trim(),
      createdAt: Timestamp.now(),
    });

    setReply("");
    setPaused(false);
    startTimer(remainingRef.current);
  };

  /* ---------------- SEEN ANALYTICS ---------------- */

  const openSeen = async () => {
    if (!frame?.views) return;

    const snaps = await Promise.all(
      frame.views.map((u) =>
        getDoc(doc(db, "profiles", u))
      )
    );

    setSeenUsers(
      snaps
        .filter((s) => s.exists())
        .map((s) => {
          const d = s.data();
          return { name: d.name, photoURL: d.photoURL };
        })
    );

    setPaused(true);
    setShowSeen(true);
  };

  if (!user || !frame) return null;

  return (
    <Screen>
      <SafeAreaView style={{ flex: 1, backgroundColor: "#000" }}>
        <Pressable
          style={styles.container}
          onPressIn={onHold}
          onPressOut={onRelease}
          onPress={onTap}
          {...pan.panHandlers}
        >
          {frame.mediaType === "video" ? (
            <Video
              source={{ uri: frame.mediaUrl! }}
              style={styles.media}
              shouldPlay={!paused}
              isLooping={false}
              resizeMode={ResizeMode.COVER}
            />
          ) : frame.mediaType === "image" ? (
            <Image
              source={{ uri: frame.mediaUrl }}
              style={styles.media}
            />
          ) : (
            <View style={styles.textWrap}>
              <Text style={styles.text}>
                {frame.textContent}
              </Text>
            </View>
          )}

          {/* PROGRESS */}
          <View style={styles.progressRow}>
            {frames.map((_, i) => {
              if (i < index)
                return (
                  <View
                    key={i}
                    style={[styles.progress, styles.fill]}
                  />
                );
              if (i === index)
                return (
                  <View key={i} style={styles.progress}>
                    <Animated.View
                      style={[
                        styles.fill,
                        {
                          width: progressAnim.interpolate({
                            inputRange: [0, 1],
                            outputRange: ["0%", "100%"],
                          }),
                        },
                      ]}
                    />
                  </View>
                );
              return <View key={i} style={styles.progress} />;
            })}
          </View>

          {/* HEADER */}
          <View style={styles.header}>
            {profile && (
              <>
                <Image
                  source={{ uri: profile.photoURL }}
                  style={styles.avatar}
                />
                <Text style={styles.name}>{profile.name}</Text>
                <Text style={styles.time}>
                  · {formatPostTime(frame.createdAt)}
                </Text>
              </>
            )}
          </View>

          {/* SEEN */}
          {uid === frame.uid && (
            <TouchableOpacity
              style={styles.seen}
              onPress={openSeen}
            >
              <Text style={{ color: "#fff" }}>
                👁 {frame.views?.length || 0}
              </Text>
            </TouchableOpacity>
          )}

          {/* CLOSE */}
          <TouchableOpacity
            style={styles.close}
            onPress={() => router.back()}
          >
            <Text style={{ color: "#fff", fontSize: 20 }}>✕</Text>
          </TouchableOpacity>

          {/* REPLY */}
          <KeyboardAvoidingView
            behavior={Platform.OS === "ios" ? "padding" : undefined}
            style={styles.replyWrap}
          >
            <TextInput
              placeholder="Reply…"
              placeholderTextColor="rgba(255,255,255,0.6)"
              value={reply}
              onChangeText={(t) => {
                setReply(t);
                setPaused(true);
              }}
              style={styles.replyInput}
            />
            <TouchableOpacity onPress={sendReply}>
              <Text style={styles.send}>Send</Text>
            </TouchableOpacity>
          </KeyboardAvoidingView>
        </Pressable>

        {/* SEEN MODAL */}
        <Modal visible={showSeen} transparent animationType="slide">
          <View style={styles.modal}>
            <FlatList
              data={seenUsers}
              keyExtractor={(_, i) => String(i)}
              renderItem={({ item }) => (
                <View style={styles.seenRow}>
                  <Image
                    source={{ uri: item.photoURL }}
                    style={styles.seenAvatar}
                  />
                  <Text style={{ color: "#fff" }}>{item.name}</Text>
                </View>
              )}
            />
            <TouchableOpacity
              onPress={() => {
                setShowSeen(false);
                setPaused(false);
                startTimer(remainingRef.current);
              }}
            >
              <Text style={styles.closeSeen}>Close</Text>
            </TouchableOpacity>
          </View>
        </Modal>
      </SafeAreaView>
    </Screen>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  container: { flex: 1 },
  media: { width, height },
  textWrap: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    padding: 32,
  },
  text: { color: "#fff", fontSize: 22, textAlign: "center" },

  progressRow: {
    position: "absolute",
    top: 8,
    left: 10,
    right: 10,
    flexDirection: "row",
    gap: 4,
  },
  progress: {
    flex: 1,
    height: 2,
    backgroundColor: "rgba(255,255,255,0.25)",
    overflow: "hidden",
  },
  fill: { height: 2, backgroundColor: "#fff" },

  header: {
    position: "absolute",
    top: 36,
    left: 16,
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  avatar: { width: 32, height: 32, borderRadius: 16 },
  name: { color: "#fff", fontSize: 14, fontWeight: "500" },
  time: { color: "rgba(255,255,255,0.7)", fontSize: 13 },

  seen: {
    position: "absolute",
    bottom: 120,
    alignSelf: "center",
  },

  close: { position: "absolute", top: 8, right: 16 },

  replyWrap: {
    position: "absolute",
    bottom: 20,
    left: 16,
    right: 16,
    flexDirection: "row",
    backgroundColor: "rgba(0,0,0,0.6)",
    borderRadius: 24,
    paddingHorizontal: 14,
    alignItems: "center",
  },
  replyInput: { flex: 1, color: "#fff", height: 44 },
  send: { color: "#fff", fontWeight: "600", paddingLeft: 12 },

  modal: {
    flex: 1,
    backgroundColor: "#000",
    paddingTop: 60,
  },
  seenRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 16,
  },
  seenAvatar: { width: 36, height: 36, borderRadius: 18 },
  closeSeen: {
    color: "#fff",
    textAlign: "center",
    padding: 16,
  },
});
