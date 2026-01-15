import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { db, auth } from "@/services/firebase";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  setDoc,
} from "firebase/firestore";
import * as Clipboard from "expo-clipboard";

export default function ProfileMenu({
  uid,
  onClose,
}: {
  uid: string;
  onClose: () => void;
}) {
  const currentUid = auth.currentUser?.uid!;

  return (
    <View style={styles.menu}>
      <Item
        label="Report"
        onPress={async () => {
          await addDoc(collection(db, "reports"), {
            reporterUid: currentUid,
            targetUid: uid,
            createdAt: Date.now(),
          });
          onClose();
        }}
      />

      <Item
        label="Block"
        onPress={async () => {
          await setDoc(
            doc(db, "blocks", currentUid, "blocked", uid),
            { createdAt: Date.now() }
          );
          onClose();
        }}
      />

      <Item
        label="Remove follower"
        onPress={async () => {
          await deleteDoc(
            doc(db, "follows", uid, "followers", currentUid)
          );
          onClose();
        }}
      />

      <Item
        label="Copy profile link"
        onPress={async () => {
          await Clipboard.setStringAsync(
            `https://saran.app/profile/${uid}`
          );
          onClose();
        }}
      />
    </View>
  );
}

function Item({
  label,
  onPress,
}: {
  label: string;
  onPress: () => void;
}) {
  return (
    <TouchableOpacity style={styles.item} onPress={onPress}>
      <Text style={styles.text}>{label}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  menu: {
    position: "absolute",
    top: 60,
    right: 16,
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 12,
    elevation: 5,
  },
  item: { paddingVertical: 12 },
  text: { fontSize: 16 },
});
