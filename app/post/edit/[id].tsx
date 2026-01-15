import { useEffect, useState } from "react";
import { SafeAreaView } from "react-native-safe-area-context";
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
} from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { doc, getDoc, updateDoc } from "firebase/firestore";
import { auth, db } from "@/services/firebase";

export default function EditPostScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();

  const [loading, setLoading] = useState(true);
  const [text, setText] = useState("");

  useEffect(() => {
    if (!id) return;

    const load = async () => {
      try {
        const snap = await getDoc(doc(db, "posts", id));
        if (!snap.exists()) {
          Alert.alert("Post not found");
          router.back();
          return;
        }

        const data = snap.data();

        // 🔐 Only owner can edit
        if (data.uid !== auth.currentUser?.uid) {
          Alert.alert("You can't edit this post");
          router.back();
          return;
        }

        setText(data.text || "");
      } catch (e) {
        Alert.alert("Failed to load post");
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [id]);

  const onSave = async () => {
    if (!id) return;

    try {
      await updateDoc(doc(db, "posts", id), {
        text: text.trim(),
        editedAt: new Date(),
      });

      Alert.alert("Updated");
      router.back();
    } catch (e) {
      Alert.alert("Update failed");
    }
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.root}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.back}>Back</Text>
        </TouchableOpacity>

        <Text style={styles.title}>Edit Post</Text>

        <TouchableOpacity onPress={onSave}>
          <Text style={styles.save}>Save</Text>
        </TouchableOpacity>
      </View>

      <TextInput
        value={text}
        onChangeText={setText}
        placeholder="Edit your post..."
        multiline
        style={styles.input}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#fff" },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },

  header: {
    height: 56,
    paddingHorizontal: 14,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    borderBottomWidth: 1,
    borderColor: "#eee",
  },

  back: { fontSize: 14, fontWeight: "600" },
  title: { fontSize: 16, fontWeight: "700" },
  save: { fontSize: 14, fontWeight: "700" },

  input: {
    padding: 14,
    fontSize: 15,
    minHeight: 160,
    textAlignVertical: "top",
  },
});
