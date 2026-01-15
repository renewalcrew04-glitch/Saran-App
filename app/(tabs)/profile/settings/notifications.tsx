import { View, Text, Switch, StyleSheet } from "react-native";
import { useEffect, useState } from "react";
import { auth, db } from "@/services/firebase";
import { doc, getDoc } from "firebase/firestore";
import { updateUserSetting } from "@/services/userSettings";

type SOSSettings = {
  enabled: boolean;
  shareLocation: boolean;
  notifyCloseFriends: boolean;
  notifyNearby: boolean;
};

export default function Notifications() {
  const uid = auth.currentUser?.uid;
  const [enabled, setEnabled] = useState(true);
  const [sos, setSOS] = useState<SOSSettings>({
    enabled: true,
    shareLocation: true,
    notifyCloseFriends: true,
    notifyNearby: false,
  });

  /* ---------------- LOAD SETTINGS ---------------- */
  useEffect(() => {
    if (!uid) return;

    getDoc(doc(db, "profiles", uid)).then((snap) => {
      if (!snap.exists()) return;

      const settings = snap.data()?.settings ?? {};

      setEnabled(settings.notifications ?? true);
      setSOS({
        enabled: settings.sos?.enabled ?? true,
        shareLocation: settings.sos?.shareLocation ?? true,
        notifyCloseFriends: settings.sos?.notifyCloseFriends ?? true,
        notifyNearby: settings.sos?.notifyNearby ?? false,
      });
    });
  }, []);

  /* ---------------- UPDATE HELPERS ---------------- */
  const toggleNotifications = async (v: boolean) => {
    if (!uid) return;
    setEnabled(v);

    await updateUserSetting(uid, "notifications", v);
  };

  const updateSOS = async (key: keyof SOSSettings, value: boolean) => {
    if (!uid) return;

    const next = { ...sos, [key]: value };
    setSOS(next);

    await updateUserSetting(uid, `sos.${key}`, value);
  };

  /* ---------------- UI ---------------- */
  return (
    <View style={styles.container}>
      {/* 🔔 NOTIFICATIONS */}
      <Row label="Enable Notifications" value={enabled} onChange={toggleNotifications} />

      {/* 🚨 SOS SETTINGS */}
      <Text style={styles.sectionTitle}>SOS Settings</Text>

      <Row label="Enable SOS" value={sos.enabled} onChange={(v) => updateSOS("enabled", v)} />
      <Row label="Share live location" value={sos.shareLocation} onChange={(v) => updateSOS("shareLocation", v)} />
      <Row label="Notify close friends" value={sos.notifyCloseFriends} onChange={(v) => updateSOS("notifyCloseFriends", v)} />
      <Row label="Notify nearby users" value={sos.notifyNearby} onChange={(v) => updateSOS("notifyNearby", v)} />
    </View>
  );
}

/* ---------------- ROW ---------------- */
function Row({
  label,
  value,
  onChange,
}: {
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <View style={styles.row}>
      <Text>{label}</Text>
      <Switch value={value} onValueChange={onChange} />
    </View>
  );
}

/* ---------------- STYLES ---------------- */
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
    paddingVertical: 12,
  },
  sectionTitle: {
    marginTop: 28,
    marginBottom: 8,
    fontWeight: "600",
    fontSize: 14,
    color: "#555",
  },
});
