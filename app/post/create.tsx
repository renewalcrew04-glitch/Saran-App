import { Redirect, useRouter } from "expo-router";
import AppHeader from "@/components/AppHeader";
import * as ImagePicker from "expo-image-picker";
import { uploadImageAsync } from "@/utils/uploadImage";
import { extractMentions } from "@/utils/extractMentions";
import { resolveMentions } from "@/services/resolveMentions";
import { notifyMentions } from "@/services/mentionNotify";

import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
} from "react-native";
import { useState } from "react";
import { Ionicons } from "@expo/vector-icons";
import { collection, doc, setDoc, serverTimestamp } from "firebase/firestore";
import { auth, db } from "@/services/firebase";
import { useProfileStore } from "@/store/profileStore";
import { useAuth } from "@/hooks/useAuth";

/* ------------------ CONSTANTS ------------------ */

const CATEGORIES = [
  "General",
  "Wellness",
  "Career",
  "Lifestyle",
  "Motherhood",
  "Relationships",
  "Creativity",
  "Travel",
  "Inspiration",
  "Beauty",
  "Fitness",
  "Food",
  "Fashion",
  "Education",
];

/* ------------------ SCREEN ------------------ */
async function generateVideoThumbnail(
  uri: string
): Promise<string | null> {
  try {
    const module = await import("expo-video-thumbnails");

    const { uri: thumbUri } =
      await module.getThumbnailAsync(uri, { time: 500 });

    return thumbUri;
  } catch {
    // Expo Go safe
    return null;
  }
}

export default function CreatePost() {
  const router = useRouter();
  const { user } = useAuth();
  const verified = useProfileStore((s) => s.verified);

  /* ------------------ STATE ------------------ */

  const [content, setContent] = useState("");
  const [category, setCategory] = useState("General");
  const [showCategoryDropdown, setShowCategoryDropdown] = useState(false);
  const [hashtags, setHashtags] = useState("");
  const [media, setMedia] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  const charCount = content.length;
  const canPublish =
  verified && (content.trim().length > 0 || media.length > 0);
  const remainingMedia = 10 - media.length;

  /* ------------------ ACTIONS ------------------ */

  const pickImage = async () => {
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    quality: 0.7,
    allowsMultipleSelection: true,
    selectionLimit: 10 - media.length,
  });

  if (!result.canceled) {
    const uris = result.assets.map(a => a.uri);
    setMedia(prev => [...prev, ...uris]);
  }
};

const handlePublish = async () => {
  if (!user || loading) return;

  if (!verified) {
    alert("Your account is under verification.");
    return;
  }

  const trimmedText = content.trim();
  if (!trimmedText && media.length === 0) return;

  try {
    setLoading(true);

    const postId = doc(collection(db, "posts")).id;

    let uploadedMedia: string[] = [];
    let thumbnail: string | null = null;

    for (const uri of media) {
      const url = await uploadImageAsync(uri, "posts");
      uploadedMedia.push(url);

      if (!thumbnail && uri.endsWith(".mp4")) {
        const thumbUri = await generateVideoThumbnail(uri);
        if (thumbUri) {
          thumbnail = await uploadImageAsync(
            thumbUri,
            "posts"
          );
        }
      }
    }

    let postType: "text" | "photo" | "video" = "text";
    if (uploadedMedia.length > 0) {
      const hasVideo = uploadedMedia.some((u) =>
        u.endsWith(".mp4")
      );
      postType = hasVideo ? "video" : "photo";
    }

    await setDoc(doc(db, "posts", postId), {
      id: postId,
      uid: user.uid,
      type: postType,
      text: trimmedText || "",
      media: uploadedMedia,
      thumbnail: thumbnail,
      category,
      hashtags,
      likesCount: 0,
      commentsCount: 0,
      visibility: "public",
      isDeleted: false,
      createdAt: serverTimestamp(),
    });

    /* ✅ MENTIONS */
    const mentions = extractMentions(trimmedText);
    if (mentions.length > 0) {
      const mentionedUserIds =
        await resolveMentions(mentions);

      await notifyMentions({
        mentionedUserIds,
        fromUserId: user.uid,
        entityId: postId,
        entityType: "post",
      });
    }

    setContent("");
    setHashtags("");
    setMedia([]);
    router.back();
  } catch (e) {
    console.error(e);
  } finally {
    setLoading(false);
  }
};

  /* ------------------ UI ------------------ */

  return (
    <View style={styles.root}>
      <AppHeader />

      <View style={styles.subHeader}>
        <Text style={styles.subHeaderTitle}>Create a Post</Text>
      </View>

      <ScrollView
        style={styles.container}
        contentContainerStyle={{ paddingBottom: 140 }}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.subtitle}>
          Share your thoughts, experiences, or inspiration with the community
        </Text>

        <Text style={styles.label}>What&apos;s on your mind?</Text>
        <TextInput
          placeholder="Share your story, thoughts, or ask a question..."
          value={content}
          onChangeText={setContent}
          multiline
          style={styles.textArea}
          placeholderTextColor="#999"
        />

        <Text style={styles.proTip}>
          Pro tip: Use #hashtags to reach more people!
        </Text>

        <Text style={styles.counter}>{charCount} characters</Text>

        <Text style={styles.label}>Category</Text>

        <TouchableOpacity
          style={styles.dropdown}
          onPress={() => setShowCategoryDropdown((p) => !p)}
        >
          <Text style={styles.dropdownText}>{category}</Text>
          <Ionicons
            name={showCategoryDropdown ? "chevron-up" : "chevron-down"}
            size={18}
          />
        </TouchableOpacity>

        {showCategoryDropdown && (
          <View style={styles.dropdownList}>
            {CATEGORIES.map((item) => (
              <TouchableOpacity
                key={item}
                style={styles.dropdownItem}
                onPress={() => {
                  setCategory(item);
                  setShowCategoryDropdown(false);
                }}
              >
                <Text
                  style={[
                    styles.dropdownItemText,
                    category === item && styles.dropdownItemActive,
                  ]}
                >
                  {item}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        )}

        <Text style={styles.label}>Additional Hashtags (optional)</Text>
        <TextInput
          placeholder="travel, adventure, lifestyle"
          value={hashtags}
          onChangeText={setHashtags}
          style={styles.input}
          placeholderTextColor="#999"
        />

        <Text style={styles.label}>Add Photos or Videos (Max 10)</Text>
        <TouchableOpacity style={styles.mediaBox} onPress={pickImage}>
          <Text style={styles.mediaText}>
            Click to upload photos or videos
          </Text>
        </TouchableOpacity>

        <Text style={styles.mediaCount}>
          {remainingMedia} more allowed
        </Text>

        <View style={styles.bottomBar}>
          <TouchableOpacity
            style={styles.cancelBtn}
            onPress={() => router.back()}
          >
            <Text style={styles.cancelText}>Cancel</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.publishBtn,
              (!canPublish || loading) && styles.publishDisabled,
            ]}
            disabled={!canPublish || loading}
            onPress={handlePublish}
          >
            <Text style={styles.publishText}>
              {loading ? "Publishing..." : "Publish Post"}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
}

/* ------------------ STYLES ------------------ */

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#fff" },
  container: { flex: 1, padding: 16 },

  subHeader: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#eee",
  },
  subHeaderTitle: { fontSize: 16, fontWeight: "700" },

  subtitle: { fontSize: 14, color: "#666", marginBottom: 20 },

  label: { fontSize: 14, fontWeight: "600", marginBottom: 6 },

  textArea: {
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 12,
    padding: 12,
    minHeight: 120,
  },

  proTip: { fontSize: 12, color: "#666", marginTop: 6 },
  counter: { textAlign: "right", fontSize: 12, color: "#999" },

  dropdown: {
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 10,
    padding: 14,
    flexDirection: "row",
    justifyContent: "space-between",
  },

  dropdownList: {
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 10,
    marginBottom: 16,
  },

  dropdownItem: { padding: 12 },
  dropdownItemText: { fontSize: 14 },
  dropdownItemActive: { fontWeight: "700" },

  input: {
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 10,
    padding: 12,
    marginBottom: 16,
  },

  mediaBox: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderStyle: "dashed",
    borderRadius: 12,
    paddingVertical: 28,
    alignItems: "center",
  },

  mediaText: { color: "#666" },
  mediaCount: { fontSize: 12, color: "#999", marginBottom: 24 },

  bottomBar: { flexDirection: "row", gap: 12 },

  cancelBtn: {
    flex: 1,
    borderWidth: 1,
    borderColor: "#ddd",
    paddingVertical: 14,
    borderRadius: 28,
    alignItems: "center",
  },
  dropdownText: {
  fontSize: 14,
  color: "#000",
},
cancelText: {
  fontSize: 14,
  color: "#000",
},

  publishBtn: {
    flex: 1,
    backgroundColor: "#000",
    paddingVertical: 14,
    borderRadius: 28,
    alignItems: "center",
  },

  publishDisabled: { opacity: 0.4 },
  publishText: { color: "#fff", fontWeight: "600" },
});
