import { View, Text, Switch, StyleSheet } from "react-native";
import { useEffect, useState } from "react";
import { auth, db } from "@/services/firebase";
import { doc, getDoc } from "firebase/firestore";
import { updateUserSetting } from "@/services/userSettings";

export default function Comments() {
  const uid = auth.currentUser?.uid!;
  const [followersOnly, setFollowersOnly] = useState(false);

  useEffect(() => {
    getDoc(doc(db, "profiles", uid)).then((snap) => {
      setFollowersOnly(
        snap.data()?.settings?.allowComments === "followers"
      );
    });
  }, []);

  const toggle = async (v: boolean) => {
    setFollowersOnly(v);
    await updateUserSetting(
  uid,
  "allowComments",
  v ? "followers" : "everyone"
);
  };

  return (
    <View style={styles.container}>
      <Row label="Only followers can comment" value={followersOnly} onChange={toggle} />
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
