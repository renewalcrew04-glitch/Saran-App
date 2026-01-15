import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  TouchableWithoutFeedback,
  Keyboard,
  Image,
  Linking,
} from "react-native";
import Checkbox from "expo-checkbox";
import FallbackAvatar from "@/components/ui/FallbackAvatar";
import { useState } from "react";
import { useRouter } from "expo-router";
import { auth, db } from "@/services/firebase";
import { doc, setDoc, getDoc } from "firebase/firestore";
import { useProfileStore } from "@/store/profileStore";
import * as ImagePicker from "expo-image-picker";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";

/* ---------------- TYPES ---------------- */
type VerificationStep = "pending" | "verified";

export default function CompleteProfile() {
  const router = useRouter();
  const updateProfile = useProfileStore((s) => s.updateProfile);

  const [name, setName] = useState("");
  const [username, setUsername] = useState("");
  const [bio, setBio] = useState("");
  const [location, setLocation] = useState("");
  const [phone, setPhone] = useState("");
  const [loading, setLoading] = useState(false);
  const [agreed, setAgreed] = useState(false);

  const [usernameStatus, setUsernameStatus] = useState<
    "idle" | "checking" | "available" | "taken"
  >("idle");

  const [avatar, setAvatar] = useState<string | null>(null);

  /* ---------------- USERNAME CHECK ---------------- */
  const checkUsername = async (value: string) => {
    const uname = value.toLowerCase().trim();
    setUsername(uname);

    if (uname.length < 3) {
      setUsernameStatus("idle");
      return;
    }

    setUsernameStatus("checking");
    const snap = await getDoc(doc(db, "usernames", uname));
    setUsernameStatus(snap.exists() ? "taken" : "available");
  };

  /* ---------------- AVATAR PICK ---------------- */
  const pickAvatar = async () => {
    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.7,
    });

    if (!res.canceled) {
      setAvatar(res.assets[0].uri);
    }
  };

  /* ---------------- PHONE VALIDATION ---------------- */
  const isValidIndianPhone = (v: string) =>
    /^[6-9]\d{9}$/.test(v);

  /* ---------------- SUBMIT ---------------- */
  const submit = async () => {
    if (!auth.currentUser) return;
    if (!name || !username || !phone) return;
    if (!agreed) return;

    if (!isValidIndianPhone(phone)) {
      alert("Enter valid 10-digit phone number");
      return;
    }

    if (usernameStatus !== "available") return;

    setLoading(true);

    let avatarUrl: string | null = null;

    /* 🔼 AVATAR UPLOAD */
    if (avatar) {
      const storage = getStorage();
      const response = await fetch(avatar);
      const blob = await response.blob();

      const avatarRef = ref(
        storage,
        `users/${auth.currentUser.uid}/avatar.jpg`
      );

      await uploadBytes(avatarRef, blob);
      avatarUrl = await getDownloadURL(avatarRef);
    }

    /* 🔐 Reserve username */
    const usernameRef = doc(db, "usernames", username);
    const existing = await getDoc(usernameRef);
    if (existing.exists()) {
      alert("Username already taken");
      setLoading(false);
      return;
    }

    await setDoc(usernameRef, { uid: auth.currentUser.uid });

    /* 👤 Update profile document */
    await setDoc(
      doc(db, "profiles", auth.currentUser.uid),
      {
        name,
        bio,
        location,
        phone: `+91${phone}`,
        ...(avatarUrl ? { avatar: avatarUrl } : {}),
        profileCompleted: true,
        verificationStep: "pending" as VerificationStep,
        termsAcceptedAt: Date.now(),
        emailVerified: false,
      },
      { merge: true }
    );

    /* 🧠 Update local store */
    await updateProfile({
      name,
      bio,
      location,
      phone: `+91${phone}`,
      avatar: avatarUrl ?? "",
      profileCompleted: true,
      verificationStep: "pending",
    });

    setLoading(false);
    router.replace("/verification/pending");
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <ScrollView
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={styles.container}
        >
          <Text style={styles.title}>Create your profile</Text>
          <Text style={styles.subtitle}>
            This helps other women know who you are
          </Text>

          {/* ---------- AVATAR ---------- */}
          <View style={{ alignItems: "center", marginBottom: 28 }}>
            {avatar ? (
              <Image
                source={{ uri: avatar }}
                style={{ width: 100, height: 100, borderRadius: 50 }}
              />
            ) : (
              <FallbackAvatar size={100} />
            )}

            <TouchableOpacity onPress={pickAvatar} style={{ marginTop: 10 }}>
              <Text style={{ color: "#aaa", fontSize: 13 }}>
                Upload profile photo
              </Text>
            </TouchableOpacity>
          </View>

          {/* ---------- FORM ---------- */}
          <Text style={styles.label}>Full Name *</Text>
          <TextInput
            placeholder="Enter your full name"
            placeholderTextColor="#666"
            value={name}
            onChangeText={setName}
            style={styles.input}
          />

          <Text style={styles.label}>Username *</Text>
          <TextInput
            placeholder="Choose a unique username"
            placeholderTextColor="#666"
            autoCapitalize="none"
            value={username}
            onChangeText={checkUsername}
            style={styles.input}
          />

          {usernameStatus === "checking" && (
            <Text style={styles.helper}>Checking availability…</Text>
          )}
          {usernameStatus === "available" && (
            <Text style={[styles.helper, { color: "#4CAF50" }]}>
              Username available
            </Text>
          )}
          {usernameStatus === "taken" && (
            <Text style={[styles.helper, { color: "#F44336" }]}>
              Username already taken
            </Text>
          )}

          <Text style={styles.label}>Bio</Text>
          <TextInput
            placeholder="Tell something about yourself"
            placeholderTextColor="#666"
            value={bio}
            onChangeText={setBio}
            style={[styles.input, { height: 90 }]}
            multiline
          />

          <Text style={styles.label}>Location</Text>
          <TextInput
            placeholder="City / State"
            placeholderTextColor="#666"
            value={location}
            onChangeText={setLocation}
            style={styles.input}
          />

          <Text style={styles.label}>Mobile Number *</Text>
          <View style={styles.phoneWrap}>
            <Text style={styles.phoneCode}>+91</Text>
            <TextInput
              placeholder="10-digit mobile number"
              placeholderTextColor="#666"
              keyboardType="number-pad"
              maxLength={10}
              value={phone}
              onChangeText={(t) =>
                setPhone(t.replace(/[^0-9]/g, ""))
              }
              style={styles.phoneInput}
            />
          </View>

          {/* ---------- TERMS ---------- */}
          <View style={styles.checkboxRow}>
            <Checkbox
              value={agreed}
              onValueChange={setAgreed}
              color={agreed ? "#fff" : undefined}
            />
            <Text style={styles.checkboxText}>
              I agree to{" "}
              <Text
                style={styles.link}
                onPress={() =>
                  Linking.openURL("https://www.saranapp.com/policies.html")
                }
              >
                Terms & Policies
              </Text>
            </Text>
          </View>

          <TouchableOpacity
            style={[
              styles.button,
              (!name ||
                !username ||
                !phone ||
                !isValidIndianPhone(phone) ||
                usernameStatus !== "available" ||
                !agreed ||
                loading) && styles.disabled,
            ]}
            disabled={
              !name ||
              !username ||
              !phone ||
              !isValidIndianPhone(phone) ||
              usernameStatus !== "available" ||
              !agreed ||
              loading
            }
            onPress={submit}
          >
            <Text style={styles.buttonText}>
              {loading ? "Creating..." : "Continue"}
            </Text>
          </TouchableOpacity>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
}

/* ---------------- STYLES ---------------- */
const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: "#000",
    padding: 24,
    justifyContent: "center",
    paddingBottom: 40,
  },
  title: {
    color: "#fff",
    fontSize: 26,
    fontWeight: "700",
    marginBottom: 6,
  },
  subtitle: {
    color: "#aaa",
    marginBottom: 24,
  },
  label: {
    color: "#aaa",
    fontSize: 13,
    marginBottom: 6,
    marginLeft: 4,
  },
  helper: {
    color: "#888",
    fontSize: 12,
    marginBottom: 10,
    marginLeft: 4,
  },
  input: {
    backgroundColor: "#111",
    color: "#fff",
    padding: 14,
    borderRadius: 14,
    marginBottom: 14,
    fontSize: 15,
  },
  phoneWrap: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#111",
    borderRadius: 14,
    marginBottom: 14,
    paddingHorizontal: 14,
  },
  phoneCode: {
    color: "#aaa",
    fontSize: 15,
    marginRight: 8,
  },
  phoneInput: {
    flex: 1,
    color: "#fff",
    fontSize: 15,
    paddingVertical: 14,
  },
  checkboxRow: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 18,
  },
  checkboxText: {
    marginLeft: 8,
    color: "#aaa",
    fontSize: 13,
  },
  link: {
    textDecorationLine: "underline",
    color: "#fff",
  },
  button: {
    backgroundColor: "#fff",
    paddingVertical: 15,
    borderRadius: 30,
    marginTop: 10,
  },
  disabled: {
    opacity: 0.4,
  },
  buttonText: {
    color: "#000",
    textAlign: "center",
    fontWeight: "600",
    fontSize: 16,
  },
});
