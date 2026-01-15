import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
} from "react-native";
import { useEffect, useState } from "react";
import {
  collection,
  query,
  where,
  onSnapshot,
  doc,
  updateDoc,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";

/* ---------------- ADMIN CONFIG ---------------- */

const ADMIN_UIDS = [
  "l73VcdJRhBd6xwbh6JVnO5WczFl2",
];

/* ---------------- TYPES ---------------- */

type User = {
  uid: string;
  name?: string;
  username?: string;
  email?: string;
};

/* ---------------- SCREEN ---------------- */

export default function AdminVerify() {
  const [users, setUsers] = useState<User[]>([]);
  const currentUid = auth.currentUser?.uid;

  /* 🔒 ADMIN GUARD */
  if (!currentUid || !ADMIN_UIDS.includes(currentUid)) {
    return (
      <View style={styles.denied}>
        <Text style={{ color: "#fff" }}>Access Denied</Text>
      </View>
    );
  }

  /* ---------------- FETCH PENDING USERS ---------------- */

  useEffect(() => {
    const q = query(
      collection(db, "profiles"),
      where("verificationStep", "==", "pending")
    );

    const unsub = onSnapshot(q, (snap) => {
      const list: User[] = [];
      snap.forEach((docu) => {
        list.push({
          uid: docu.id,
          ...(docu.data() as any),
        });
      });
      setUsers(list);
    });

    return unsub;
  }, []);

  /* ---------------- APPROVE USER ---------------- */

  const approve = async (uid: string) => {
    await updateDoc(doc(db, "profiles", uid), {
      verified: true,
      verificationStep: "verified",
      verifiedAt: Date.now(),
      verifiedBy: currentUid, // ✅ audit trail
    });
  };

  /* ---------------- UI ---------------- */

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Pending Verifications</Text>

      <FlatList
        data={users}
        keyExtractor={(item) => item.uid}
        ListEmptyComponent={
          <Text style={styles.empty}>No pending users</Text>
        }
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.name}>
              {item.name || "No name"}
            </Text>
            <Text style={styles.sub}>
              @{item.username || "no-username"}
            </Text>
            <Text style={styles.sub}>{item.email}</Text>

            <TouchableOpacity
              style={styles.btn}
              onPress={() => approve(item.uid)}
            >
              <Text style={styles.btnText}>Approve</Text>
            </TouchableOpacity>
          </View>
        )}
      />
    </View>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#000",
    padding: 20,
  },
  denied: {
    flex: 1,
    backgroundColor: "#000",
    justifyContent: "center",
    alignItems: "center",
  },
  title: {
    color: "#fff",
    fontSize: 22,
    fontWeight: "700",
    marginBottom: 16,
  },
  empty: {
    color: "#888",
    textAlign: "center",
    marginTop: 40,
  },
  card: {
    backgroundColor: "#111",
    padding: 16,
    borderRadius: 16,
    marginBottom: 12,
  },
  name: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "600",
  },
  sub: {
    color: "#aaa",
    fontSize: 13,
    marginTop: 2,
  },
  btn: {
    backgroundColor: "#fff",
    marginTop: 12,
    paddingVertical: 10,
    borderRadius: 20,
  },
  btnText: {
    color: "#000",
    textAlign: "center",
    fontWeight: "600",
  },
});
