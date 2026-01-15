import { View, Text, TextInput, TouchableOpacity } from "react-native";
import { useState } from "react";
import { sendPasswordResetEmail } from "firebase/auth";
import { auth } from "@/services/firebase";
import { useRouter } from "expo-router";

export default function ForgotPassword() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);

  const resetPassword = async () => {
    if (!email) {
      alert("Enter your email address");
      return;
    }

    try {
      setLoading(true);
      await sendPasswordResetEmail(
        auth,
        email.toLowerCase().trim()
      );

      alert(
        "Password reset email sent. Check your inbox."
      );
      router.back();
    } catch (e: any) {
      alert(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View
      style={{
        flex: 1,
        backgroundColor: "#000",
        padding: 24,
        justifyContent: "center",
      }}
    >
      <Text
        style={{
          color: "#fff",
          fontSize: 26,
          marginBottom: 12,
        }}
      >
        Reset password
      </Text>

      <Text
        style={{
          color: "#aaa",
          marginBottom: 32,
        }}
      >
        Enter your email address and we’ll send you a reset link.
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
          marginBottom: 32,
        }}
      />

      <TouchableOpacity
        onPress={resetPassword}
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
          {loading ? "Sending..." : "Send reset link"}
        </Text>
      </TouchableOpacity>
    </View>
  );
}
