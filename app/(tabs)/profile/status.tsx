import { View, Text, StyleSheet } from "react-native";
import { useEffect, useState } from "react";
import { auth, db } from "@/services/firebase";
import { doc, getDoc } from "firebase/firestore";

type AccountState = "clean" | "warning" | "restricted" | "banned";

export default function AccountStatus() {
  const uid = auth.currentUser?.uid!;
  const [status, setStatus] = useState<AccountState>("clean");
  const [reason, setReason] = useState("");

  useEffect(() => {
    if (!uid) return;

    getDoc(doc(db, "profiles", uid)).then((snap) => {
      if (!snap.exists()) return;

      const data = snap.data();

      if (data.accountStatus) {
        setStatus(data.accountStatus);
        setReason(data.accountStatusReason || "");
      }
    });
  }, [uid]);

  return (
    <View style={styles.container}>
      <Text style={styles.label}>
        Status: {status.toUpperCase()}
      </Text>

      {reason ? (
        <Text style={styles.reason}>
          Reason: {reason}
        </Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 24,
  },
  label: {
    fontSize: 16,
    fontWeight: "600",
  },
  reason: {
    marginTop: 8,
    fontSize: 14,
    color: "#666",
  },
});
