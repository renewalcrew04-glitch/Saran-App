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
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "@/services/firebase";
import { useRouter } from "expo-router";
import { doc, getDoc } from "firebase/firestore";

export default function Login() {
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const login = async () => {
    if (!email || !password) {
      alert("Enter email and password");
      return;
    }

    try {
      setLoading(true);

      const res = await signInWithEmailAndPassword(
        auth,
        email.toLowerCase().trim(),
        password
      );

      const snap = await getDoc(doc(db, "profiles", res.user.uid));

      if (!snap.exists()) {
        alert("Profile not found");
        return;
      }

      const profile = snap.data();

      if (!profile.profileCompleted) {
        router.replace("/profile/complete");
        return;
      }

      if (profile.verificationStep !== "verified") {
        router.replace("/verification/pending");
        return;
      }

      router.replace("/(tabs)/home");
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
            paddingBottom: 40,
          }}
        >
          <Text
            style={{
              color: "#fff",
              fontSize: 28,
              fontWeight: "600",
              marginBottom: 8,
            }}
          >
            Welcome to SARAN
          </Text>

          <Text style={{ color: "#aaa", marginBottom: 32 }}>
            Women-only community
          </Text>

          <TextInput
            placeholder="Enter your email address"
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
              marginBottom: 20,
            }}
          />

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
              marginBottom: 32,
            }}
          />

          <TouchableOpacity
            onPress={login}
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
              {loading ? "Logging in..." : "Login"}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => router.push("/(auth)/forgot-password")}
            style={{ marginTop: 16 }}
          >
            <Text style={{ color: "#aaa", textAlign: "center", fontSize: 13 }}>
              Forgot password?
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => router.push("/(auth)/signup")}
            style={{ marginTop: 24 }}
          >
            <Text style={{ color: "#fff", textAlign: "center", fontSize: 14 }}>
              New here? Create an account
            </Text>
          </TouchableOpacity>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
}
