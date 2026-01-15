import { View, Text, Switch, StyleSheet } from "react-native";
import { useEffect, useState } from "react";
import { auth, db } from "@/services/firebase";
import { doc, getDoc } from "firebase/firestore";
import { updateUserSetting } from "@/services/userSettings";

export default function Privacy() {
  const uid = auth.currentUser?.uid;
  const [enabled, setEnabled] = useState(true);

  useEffect(() => {
    if (!uid) return;

    getDoc(doc(db, "profiles", uid)).then((snap) => {
      if (snap.exists()) {
        setEnabled(snap.data()?.settings?.notifications ?? true);
      }
    });
  }, []);

  const toggle = async (v: boolean) => {
    if (!uid) return;

    setEnabled(v);
    await updateUserSetting(uid, "notifications", v);
  };

  return (
    <View style={styles.container}>
      <Row label="Enable Notifications" value={enabled} onChange={toggle} />
    </View>
  );
}

function Row({ label, value, onChange }: any) {
  return (
    <View style={styles.row}>
      <Text>{label}</Text>
      <Switch value={value} onValueChange={onChange} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#fff",
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
});
