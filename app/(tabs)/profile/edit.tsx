import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Image,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useState } from "react";
import * as ImagePicker from "expo-image-picker";
import { useProfileStore } from "@/store/profileStore";
import { uploadImageAsync } from "@/utils/uploadImage";

export default function EditProfile() {
  const router = useRouter();

  /* ===== STORE ===== */
  const {
    name,
    bio,
    location,
    website,
    avatar,
    cover,
    updateProfile,
  } = useProfileStore();

  /* ===== LOCAL STATE (SAFE DEFAULTS) ===== */
  const [localName, setLocalName] = useState(name || "");
  const [localBio, setLocalBio] = useState(bio || "");
  const [localLocation, setLocalLocation] = useState(location || "");
  const [localWebsite, setLocalWebsite] = useState(website || "");
  const [saving, setSaving] = useState(false);

  /* ===== IMAGE PICKERS ===== */
  const pickAvatar = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });

    if (result.canceled) return;

    const uploadedUrl = await uploadImageAsync(
      result.assets[0].uri,
      "profile"
    );

    await updateProfile({ avatar: uploadedUrl });
  };

  const pickCover = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [3, 1],
      quality: 0.8,
    });

    if (result.canceled) return;

    const uploadedUrl = await uploadImageAsync(
      result.assets[0].uri,
      "profile"
    );

    await updateProfile({ cover: uploadedUrl });
  };

  /* ===== SAVE ===== */
  const handleSave = async () => {
    if (saving) return;

    setSaving(true);
    await updateProfile({
      name: localName.trim(),
      bio: localBio.trim(),
      location: localLocation.trim(),
      website: localWebsite.trim(),
    });
    setSaving(false);

    router.back();
    /* 🔁 FORCE RE-READ FROM STORE */
router.replace("/profile/individual");
  };

  return (
    <View style={styles.screen}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingBottom: 140 }}
      >
        {/* HEADER */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()}>
            <Ionicons name="arrow-back" size={22} color="#000" />
          </TouchableOpacity>

          <Text style={styles.headerTitle}>Edit Profile</Text>
          <View style={{ width: 22 }} />
        </View>

        {/* COVER */}
        <View style={styles.cover}>
          {!!cover && (
            <Image
              source={{ uri: cover }}
              style={StyleSheet.absoluteFill}
            />
          )}

          <TouchableOpacity
            style={styles.coverCamera}
            onPress={pickCover}
          >
            <Ionicons name="camera" size={18} color="#fff" />
          </TouchableOpacity>
        </View>

        {/* AVATAR */}
        <View style={styles.avatarSection}>
          <View style={styles.avatarWrapper}>
            <Image
              source={{
                uri:
                  avatar ||
                  "https://ui-avatars.com/api/?name=User&background=000000&color=ffffff",
              }}
              style={styles.avatar}
            />

            <TouchableOpacity
              style={styles.avatarCamera}
              onPress={pickAvatar}
            >
              <Ionicons name="camera" size={14} color="#fff" />
            </TouchableOpacity>
          </View>
        </View>

        {/* FORM */}
        <View style={styles.form}>
          {/* NAME */}
          <View style={styles.field}>
            <Text style={styles.label}>Name</Text>
            <TextInput
              value={localName}
              onChangeText={setLocalName}
              placeholder="Your name"
              style={styles.input}
              placeholderTextColor="#999"
            />
          </View>

          {/* WEBSITE */}
          <View style={styles.field}>
            <Text style={styles.label}>Website</Text>
            <TextInput
              value={localWebsite}
              onChangeText={setLocalWebsite}
              placeholder="https://yourwebsite.com"
              style={styles.input}
              placeholderTextColor="#999"
            />
          </View>

          {/* BIO */}
          <View style={styles.field}>
            <Text style={styles.label}>Bio</Text>
            <TextInput
              value={localBio}
              onChangeText={(text) =>
                text.length <= 100 && setLocalBio(text)
              }
              placeholder="Write something about you"
              multiline
              style={styles.bioInput}
              placeholderTextColor="#999"
            />
            <Text style={styles.counter}>
              {localBio.length}/100
            </Text>
          </View>

          {/* LOCATION */}
          <View style={styles.field}>
            <Text style={styles.label}>Location</Text>
            <TextInput
              value={localLocation}
              onChangeText={setLocalLocation}
              placeholder="City"
              style={styles.input}
              placeholderTextColor="#999"
            />
          </View>
        </View>
      </ScrollView>

      {/* SAVE */}
      <View style={styles.bottomBar}>
        <TouchableOpacity
          style={styles.saveButton}
          onPress={handleSave}
          disabled={saving}
        >
          <Text style={styles.saveButtonText}>
            Save changes
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

/* ===== STYLES ===== */
const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#fff" },

  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    padding: 16,
    borderBottomWidth: 1,
    borderColor: "#eee",
  },
  headerTitle: { fontSize: 16, fontWeight: "600" },

  cover: {
    height: 140,
    backgroundColor: "#eee",
    justifyContent: "flex-end",
    alignItems: "flex-end",
    padding: 12,
  },
  coverCamera: {
    backgroundColor: "#000",
    padding: 8,
    borderRadius: 20,
  },

  avatarSection: {
    alignItems: "center",
    marginTop: -40,
    marginBottom: 12,
  },
  avatarWrapper: { width: 88, height: 88 },
  avatar: {
    width: 88,
    height: 88,
    borderRadius: 44,
    borderWidth: 3,
    borderColor: "#fff",
  },
  avatarCamera: {
    position: "absolute",
    bottom: -2,
    right: -2,
    backgroundColor: "#000",
    borderRadius: 13,
    padding: 6,
  },

  form: { paddingHorizontal: 16 },
  field: { marginBottom: 18 },
  label: { fontSize: 12, color: "#666", marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 10,
    padding: 12,
  },
  bioInput: {
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 10,
    padding: 12,
    height: 90,
    textAlignVertical: "top",
  },
  counter: {
    fontSize: 11,
    color: "#999",
    textAlign: "right",
  },

  bottomBar: {
    position: "absolute",
    bottom: 10,
    left: 80,
    right: 80,
  },
  saveButton: {
    backgroundColor: "#000",
    paddingVertical: 14,
    borderRadius: 28,
    alignItems: "center",
  },
  saveButtonText: {
    color: "#fff",
    fontWeight: "600",
  },
});
