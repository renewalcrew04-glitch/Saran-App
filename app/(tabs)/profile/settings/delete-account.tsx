import { View, Text, StyleSheet, TouchableOpacity, Alert } from "react-native";
import { useRouter } from "expo-router";
import { auth, db } from "@/services/firebase";
import { deleteUser } from "firebase/auth";
import { doc, deleteDoc, getDoc } from "firebase/firestore";
import {
  getStorage,
  ref,
  deleteObject,
} from "firebase/storage";
import { useAuthStore } from "@/store/authStore";
import { useProfileStore } from "@/store/profileStore";

export default function DeleteAccount() {
  const router = useRouter();

  const handleDelete = () => {
    Alert.alert(
      "Delete account",
      "This will permanently delete your account, posts, messages, and profile data. This action cannot be undone.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete",
          style: "destructive",
          onPress: confirmDelete,
        },
      ]
    );
  };

  const confirmDelete = async () => {
    const user = auth.currentUser;
    if (!user) return;

    try {
      const uid = user.uid;

      /* 🔹 GET PROFILE (for username) */
      const profileSnap = await getDoc(doc(db, "profiles", uid));
      const profile = profileSnap.data();

      /* 🔹 DELETE PROFILE DOC */
      await deleteDoc(doc(db, "profiles", uid));

      /* 🔹 DELETE USERNAME RESERVATION */
      if (profile?.username) {
        await deleteDoc(doc(db, "usernames", profile.username));
      }

      /* 🔹 DELETE STORAGE FILES */
      const storage = getStorage();

      await Promise.allSettled([
        deleteObject(ref(storage, `profile/${uid}/avatar.jpg`)),
        deleteObject(ref(storage, `profile/${uid}/cover.jpg`)),
      ]);

      /* 🔹 DELETE AUTH USER */
      await deleteUser(user);

      /* 🔹 RESET STORES */
      useAuthStore.setState({ user: null });
      await useProfileStore.getState().resetProfile();

      /* 🔹 REDIRECT */
      router.replace("/(auth)/login");
    } catch (err) {
      Alert.alert(
        "Unable to delete account",
        "Please re-login and try again."
      );
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Delete Account</Text>

      <Text style={styles.warning}>
        Deleting your account will permanently remove:
        {"\n"}• Profile & photos
        {"\n"}• Posts & interactions
        {"\n"}• Messages & activity
      </Text>

      <TouchableOpacity
        style={styles.deleteBtn}
        onPress={handleDelete}
      >
        <Text style={styles.deleteText}>
          Permanently Delete Account
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    padding: 24,
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    marginBottom: 12,
  },
  warning: {
    color: "#555",
    lineHeight: 22,
    marginBottom: 32,
  },
  deleteBtn: {
    backgroundColor: "#ff3b30",
    paddingVertical: 14,
    borderRadius: 30,
  },
  deleteText: {
    color: "#fff",
    textAlign: "center",
    fontWeight: "700",
    fontSize: 16,
  },
});
