import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  TouchableWithoutFeedback,
  Keyboard,
} from "react-native";
import { useState } from "react";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "@/services/firebase";
import { useRouter } from "expo-router";
import { doc, setDoc } from "firebase/firestore";
import { useProfileStore } from "@/store/profileStore";

export default function Signup() {
  const router = useRouter();
  const hydrate = useProfileStore.getState().hydrate;

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const signup = async () => {
    if (!email || !password || !confirmPassword) {
      alert("Fill all fields");
      return;
    }

    if (password.length < 6) {
      alert("Password must be at least 6 characters");
      return;
    }

    if (password !== confirmPassword) {
      alert("Passwords do not match");
      return;
    }

    try {
      setLoading(true);

      const res = await createUserWithEmailAndPassword(
        auth,
        email.toLowerCase().trim(),
        password
      );

      // 🔐 Minimal profile document
      await setDoc(doc(db, "profiles", res.user.uid), {
        uid: res.user.uid,
        email: email.toLowerCase().trim(),
        profileCompleted: false,
        verificationStep: "pending",
        verified: false,
        createdAt: Date.now(),
      });

      // ✅ HYDRATE PROFILE STATE
      await hydrate(res.user.uid);

      // ➜ Move to profile completion
      router.replace("/profile/complete");
    } catch (e: any) {
      alert(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <ScrollView
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={{
            flexGrow: 1,
            backgroundColor: "#000",
            padding: 24,
            justifyContent: "center",
          }}
        >
          <Text style={{ color: "#fff", fontSize: 28, marginBottom: 12 }}>
            Create Account
          </Text>

          <TextInput
            placeholder="Email address"
            placeholderTextColor="#666"
            autoCapitalize="none"
            keyboardType="email-address"
            value={email}
            onChangeText={setEmail}
            style={{
              color: "#fff",
              borderBottomWidth: 1,
              borderBottomColor: "#444",
              fontSize: 16,
              paddingVertical: 12,
              marginBottom: 6,
            }}
          />

          <Text style={{ color: "#777", fontSize: 12, marginBottom: 14 }}>
            A verification link will be sent after profile completion.
          </Text>

          <TextInput
            placeholder="Password"
            placeholderTextColor="#666"
            secureTextEntry
            value={password}
            onChangeText={setPassword}
            style={{
              color: "#fff",
              borderBottomWidth: 1,
              borderBottomColor: "#444",
              fontSize: 16,
              paddingVertical: 12,
              marginBottom: 20,
            }}
          />

          <TextInput
            placeholder="Confirm password"
            placeholderTextColor="#666"
            secureTextEntry
            value={confirmPassword}
            onChangeText={setConfirmPassword}
            style={{
              color: "#fff",
              borderBottomWidth: 1,
              borderBottomColor: "#444",
              fontSize: 16,
              paddingVertical: 12,
              marginBottom: 32,
            }}
          />

          <TouchableOpacity
            onPress={signup}
            disabled={loading}
            style={{
              backgroundColor: "#fff",
              paddingVertical: 14,
              borderRadius: 30,
            }}
          >
            <Text
              style={{
                color: "#000",
                textAlign: "center",
                fontSize: 16,
                fontWeight: "600",
              }}
            >
              {loading ? "Creating..." : "Create Account"}
            </Text>
          </TouchableOpacity>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
}
