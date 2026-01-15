import { View, Text, Switch, StyleSheet } from "react-native";
import { auth, db } from "@/services/firebase";
import { updateUserSetting } from "@/services/userSettings";
import { useState } from "react";

export default function Likes() {
  const uid = auth.currentUser?.uid!;
  const [show, setShow] = useState(true);

  const toggle = async (v: boolean) => {
    setShow(v);
    await updateUserSetting(uid, "showLikeCounts", v);
  };

  return (
    <View style={styles.container}>
      <Row label="Show like & share counts" value={show} onChange={toggle} />
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
  container: { flex: 1, padding: 20, backgroundColor: "#fff" },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
});
