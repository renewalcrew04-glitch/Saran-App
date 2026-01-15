import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Image,
  ActivityIndicator,
} from "react-native";
import {
  FILTERS,
  SFrameFilter,
  applyFilter,
  FilterPreview,
} from "@/components/sframe/filters";
import UploadQueueStatus from "@/components/upload/UploadQueueStatus";
import { Video, ResizeMode } from "expo-av";
import { useAuthReady } from "@/hooks/useAuthReady";
import { useEffect, useState } from "react";
import { useRouter } from "expo-router";
import * as ImagePicker from "expo-image-picker";
import {
  collection,
  doc,
  serverTimestamp,
  Timestamp,
  setDoc,
} from "firebase/firestore";
import { uploadMediaAsync } from "@/utils/uploadImage";
import { savePendingUpload, consumePendingUploads } from "@/utils/uploadQueue";
import { FontAwesome6 } from "@expo/vector-icons";
import Screen from "@components/Screen";
import { db, auth } from "@/services/firebase";
import { Colors } from "@constants/colors";

import { extractMentions } from "@/utils/extractMentions";
import { resolveMentions } from "@/services/resolveMentions";
import { notifyMentions } from "@/services/mentionNotify";

type Mode = "select" | "text" | "media";

const MOODS = ["Calm", "Glow-up", "Proud", "Tired", "Learning"];
const DURATIONS = [1, 3, 6, 12, 24];

export default function CreateSFrame() {
  const router = useRouter();
  const user = useAuthReady();

  /* ---------- STATE HOOKS ---------- */
  const [filter, setFilter] = useState<SFrameFilter>("normal");
  const [mode, setMode] = useState<Mode>("select");
  const [text, setText] = useState("");
  const [media, setMedia] =
    useState<ImagePicker.ImagePickerAsset | null>(null);
  const [mood, setMood] = useState("Calm");
  const [duration, setDuration] = useState(24);
  const [progress, setProgress] = useState(0);
  const [loading, setLoading] = useState(false);

  /* ---------- EFFECTS (ALWAYS RUN) ---------- */

  // 🔁 AUTO-RETRY PENDING UPLOADS
  useEffect(() => {
    if (!user) return;

    (async () => {
      const pending = await consumePendingUploads();
      for (const job of pending) {
        try {
          await uploadMediaAsync(job.uri, "sframes", job.mimeType);
        } catch {
          await savePendingUpload(job);
        }
      }
    })();
  }, [user]);

  /* ---------- AUTH GATE (AFTER HOOKS) ---------- */

  if (!user) {
  return (
    <Screen>
      <View style={styles.loader}>
        <ActivityIndicator />
      </View>
    </Screen>
  );
}

  const uid = user.uid;

  /* ---------- CAMERA ---------- */
  const openCamera = async () => {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== "granted") return;

    const result = await ImagePicker.launchCameraAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.All,
      videoMaxDuration: 20,
      quality: 0.7,
    });

    if (!result.canceled) {
      setMedia(result.assets[0]);
      setMode("media");
    }
  };

  /* ---------- CREATE FRAME ---------- */
  const createFrame = async () => {
    if (!uid) return;

    try {
      setLoading(true);

      let mediaUrl: string | null = null;
      let mediaType: "text" | "photo" | "video" = "text";

      if (media) {
        let uploadUri = media.uri;

        if (media.type === "image" && filter !== "normal") {
          uploadUri = await applyFilter(uploadUri, filter);
        }

        try {
          mediaUrl = await uploadMediaAsync(
            uploadUri,
            "sframes",
            media.mimeType,
            setProgress
          );
        } catch {
          await savePendingUpload({
            uri: uploadUri,
            mimeType: media.mimeType,
            createdAt: Date.now(),
          });
          throw new Error("Upload queued");
        }

        mediaType = media.type === "video" ? "video" : "photo";
      }

      const expiresAt = Timestamp.fromDate(
        new Date(Date.now() + duration * 60 * 60 * 1000)
      );

      const frameRef = doc(collection(db, "sframes"));
      const frameId = frameRef.id;

      await setDoc(frameRef, {
        uid,
        mediaType,
        mediaUrl,
        filter: mediaType === "photo" ? filter : null,
        textContent: media ? null : text.trim(),
        mood,
        createdAt: serverTimestamp(),
        expiresAt,
        views: [],
        echoes: [],
      });

      if (text.trim()) {
        const mentions = extractMentions(text);
        if (mentions.length && auth.currentUser?.uid) {
          const mentionedUserIds = await resolveMentions(mentions);
          await notifyMentions({
            mentionedUserIds,
            fromUserId: auth.currentUser.uid,
            entityId: frameId,
            entityType: "sframe",
          });
        }
      }

      router.back();
    } finally {
      setLoading(false);
    }
  };

  /* ---------- UI ---------- */
  return (
    <Screen>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.back}>←</Text>
        </TouchableOpacity>
        <Text style={styles.title}>S-Frame</Text>
        <View style={{ width: 24 }} />
      </View>

      {loading && progress > 0 && (
        <Text style={styles.progress}>Uploading… {progress}%</Text>
      )}

      <UploadQueueStatus />

      {mode === "select" && (
        <View style={styles.center}>
          <View style={styles.logo}>
            <Image
              source={require("@/assets/images/icon.png")}
              style={styles.logoImage}
            />
          </View>

          <Text style={styles.heading}>Create Your Moment</Text>
          <Text style={styles.sub}>Choose how you want to share</Text>

          <View style={styles.row}>
            <TouchableOpacity style={styles.card} onPress={openCamera}>
              <FontAwesome6 name="camera" size={28} color={Colors.black} />
              <Text style={styles.cardText}>Camera</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.card}
              onPress={() => setMode("text")}
            >
              <FontAwesome6
                name="money-check"
                solid
                size={20}
                color={Colors.black}
              />
              <Text style={styles.cardText}>Text</Text>
            </TouchableOpacity>
          </View>
        </View>
      )}

      {mode === "text" && (
        <View style={styles.editor}>
          <View style={styles.preview}>
            <TextInput
              value={text}
              onChangeText={setText}
              placeholder="Write your moment…"
              placeholderTextColor={Colors.gray500}
              multiline
              maxLength={200}
              style={styles.textInput}
            />
          </View>

          {media &&
            (media.type === "image" ? (
              <FilterPreview uri={media.uri} filter={filter} size={320} />
            ) : (
              <Video
                source={{ uri: media.uri }}
                style={styles.previewMedia}
                resizeMode={ResizeMode.COVER}
                shouldPlay
                isLooping
              />
            ))}

          <View style={styles.filterRow}>
            {FILTERS.map((f) => (
              <TouchableOpacity
                key={f.key}
                onPress={() => setFilter(f.key)}
                style={[
                  styles.filterChip,
                  filter === f.key && styles.filterChipActive,
                ]}
              >
                <Text
                  style={{
                    color:
                      filter === f.key ? Colors.white : Colors.black,
                  }}
                >
                  {f.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <TouchableOpacity
            style={styles.share}
            onPress={createFrame}
            disabled={!text.trim() || loading}
          >
            {loading ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.shareText}>✓ Share S-Frame</Text>
            )}
          </TouchableOpacity>
        </View>
      )}

      {mode === "media" && media && (
        <View style={styles.editor}>
          <Image source={{ uri: media.uri }} style={styles.previewMedia} />
          <TouchableOpacity style={styles.share} onPress={createFrame}>
            <Text style={styles.shareText}>✓ Share S-Frame</Text>
          </TouchableOpacity>
        </View>
      )}
    </Screen>
  );
}

/* ---------- STYLES ---------- */
const styles = StyleSheet.create({
  loader: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  header: {
    height: 52,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 16,
  },
  back: { fontSize: 22 },
  title: { fontSize: 20, fontWeight: "700" },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingBottom: 60,
  },
  logo: {
    width: 64,
    height: 64,
    borderRadius: 16,
    backgroundColor: Colors.black,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 16,
  },
  logoImage: { width: 40, height: 40, resizeMode: "contain" },
  heading: { fontSize: 18, fontWeight: "600" },
  sub: { color: Colors.gray700, marginTop: 4 },
  row: { flexDirection: "row", gap: 16, marginTop: 32 },
  card: {
    width: 120,
    height: 120,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.gray300,
    alignItems: "center",
    justifyContent: "center",
  },
  cardText: { marginTop: 8, fontWeight: "500" },
  editor: { flex: 1, padding: 20 },
  preview: {
    height: 280,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: Colors.gray300,
    justifyContent: "center",
    alignItems: "center",
    padding: 24,
    marginBottom: 20,
  },
  textInput: { fontSize: 20, textAlign: "center", width: "100%" },
  filterRow: {
    flexDirection: "row",
    justifyContent: "center",
    marginTop: 12,
    flexWrap: "wrap",
  },
  filterChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    marginHorizontal: 6,
    backgroundColor: Colors.gray200,
  },
  filterChipActive: {
    backgroundColor: Colors.black,
  },
  share: {
    backgroundColor: Colors.black,
    padding: 16,
    borderRadius: 30,
    alignItems: "center",
    marginTop: 20,
  },
  shareText: { color: Colors.white, fontWeight: "600" },
  previewMedia: { flex: 1, borderRadius: 20 },
  progress: { textAlign: "center", marginVertical: 8 },
});
