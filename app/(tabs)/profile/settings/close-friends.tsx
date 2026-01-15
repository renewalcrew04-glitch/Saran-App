import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
} from "react-native";
import { useEffect, useState } from "react";
import { auth, db } from "@/services/firebase";
import {
  doc,
  setDoc,
  deleteDoc,
  getDocs,
  collection,
} from "firebase/firestore";
import { getFollowing } from "@/services/followService";
import { getProfileLite } from "@/services/profileLookup";

type UserLite = {
  uid: string;
  name?: string;
};

export default function CloseFriends() {
  const user = auth.currentUser;
  if (!user) return null;

  const uid = user.uid;

  const [users, setUsers] = useState<UserLite[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());

  useEffect(() => {
    load();
  }, []);

  async function load() {
    // 1️⃣ Following list
    const following = await getFollowing(uid);

    // 2️⃣ Profiles
    const profiles = await Promise.all(
      following.map((f) => getProfileLite(f.uid))
    );

    setUsers(
      profiles
        .filter(Boolean)
        .map((p, i) => ({
          uid: following[i].uid,
          name: p!.name,
        }))
    );

    // 3️⃣ Existing close friends
    const snap = await getDocs(
      collection(db, "profiles", uid, "closeFriends")
    );

    setSelected(new Set(snap.docs.map((d) => d.id)));
  }

  async function toggle(targetUid: string) {
    const ref = doc(
      db,
      "profiles",
      uid,
      "closeFriends",
      targetUid
    );

    const next = new Set(selected);

    if (next.has(targetUid)) {
      await deleteDoc(ref);
      next.delete(targetUid);
    } else {
      await setDoc(ref, {
        createdAt: Date.now(),
      });
      next.add(targetUid);
    }

    setSelected(next);
  }

  return (
    <FlatList
      data={users}
      keyExtractor={(i) => i.uid}
      renderItem={({ item }) => (
        <TouchableOpacity
          style={styles.row}
          onPress={() => toggle(item.uid)}
        >
          <Text style={styles.name}>
            {item.name ?? "User"}
          </Text>

          <Text style={styles.check}>
            {selected.has(item.uid) ? "✓" : ""}
          </Text>
        </TouchableOpacity>
      )}
      ListEmptyComponent={
        <Text style={styles.empty}>
          Follow users to add close friends
        </Text>
      }
    />
  );
}

const styles = StyleSheet.create({
  row: {
    padding: 16,
    flexDirection: "row",
    justifyContent: "space-between",
    borderBottomWidth: 0.5,
    borderColor: "#eee",
  },
  name: {
    fontSize: 16,
  },
  check: {
    fontSize: 18,
    fontWeight: "600",
  },
  empty: {
    textAlign: "center",
    marginTop: 40,
    color: "#777",
  },
});
