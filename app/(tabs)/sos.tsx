import React, { useEffect, useRef, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Alert,
  Modal,
  Vibration,
  Pressable,
} from "react-native";
import * as Location from "expo-location";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import { auth } from "@/services/firebase";
import { triggerSOS } from "@/services/sos";
import { notifyCloseFriends } from "@/services/sosNotify";
import { startLiveLocation, stopLiveLocation } from "@/services/sosLocation";
import { cancelSOS } from "@/services/sos";

const HOLD_DURATION = 3000;

export default function SOS() {
  const router = useRouter();

  const [target, setTarget] = useState<"friends" | "nearby">("friends");
  const [message, setMessage] = useState("");
  const [locationAllowed, setLocationAllowed] = useState(false);
  const [holding, setHolding] = useState(false);
  const [confirmVisible, setConfirmVisible] = useState(false);
  const [sending, setSending] = useState(false);

  const holdTimer = useRef<NodeJS.Timeout | null>(null);

  /* ---------------- LOCATION PERMISSION ---------------- */
  useEffect(() => {
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      setLocationAllowed(status === "granted");
    })();
  }, []);

  /* ---------------- PRESS & HOLD ---------------- */
  const startHold = async () => {
    if (sending) return;

    setHolding(true);
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

    holdTimer.current = setTimeout(() => {
      setHolding(false);
      setConfirmVisible(true);
    }, HOLD_DURATION);
  };

  const cancelHold = () => {
    if (holdTimer.current) clearTimeout(holdTimer.current);
    setHolding(false);
  };

  /* ---------------- SEND SOS ---------------- */
  const sendSOS = async () => {
    if (!auth.currentUser) return;

    setConfirmVisible(false);
    setSending(true);

    Vibration.vibrate([0, 500, 300, 500]);
    await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);

    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== "granted") {
        Alert.alert("Location Required", "Location access is required.");
        setSending(false);
        return;
      }

      const loc = await Location.getCurrentPositionAsync({});

      await triggerSOS(auth.currentUser.uid, {
        target,
        message,
        location: {
          lat: loc.coords.latitude,
          lng: loc.coords.longitude,
        },
      });

      await notifyCloseFriends(auth.currentUser.uid, auth.currentUser.uid);
      await startLiveLocation(auth.currentUser.uid);

      Alert.alert("SOS Sent", "Your emergency alert has been sent.");
    } catch (e) {
      Alert.alert("Error", "Failed to send SOS. Please try again.");
    } finally {
      setSending(false);
    }
  };

  /* ---------------- CANCEL SOS ---------------- */
  const cancelSOSAction = async () => {
    if (!auth.currentUser) return;

    Alert.alert("Cancel SOS?", "This will stop emergency alerts.", [
      { text: "No" },
      {
        text: "Yes, Cancel",
        style: "destructive",
        onPress: async () => {
          await cancelSOS(auth.currentUser!.uid);
          stopLiveLocation();
          Alert.alert("SOS Cancelled", "Emergency alert stopped.");
        },
      },
    ]);
  };

  /* ---------------- UI ---------------- */
  return (
    <View style={styles.container}>

      <Text style={styles.title}>Emergency SOS</Text>
      <Text style={styles.subtitle}>Your safety is our priority</Text>

      <Text style={styles.label}>Send alert to:</Text>

      <View style={styles.row}>
        <TouchableOpacity
          style={[styles.option, target === "friends" && styles.active]}
          onPress={() => setTarget("friends")}
        >
          <Text style={[styles.optionTitle, target === "friends" && styles.activeText]}>
            Close Friends
          </Text>
          <Text style={styles.optionSub}>Selected contacts</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.option, target === "nearby" && styles.active]}
          onPress={() => setTarget("nearby")}
        >
          <Text style={[styles.optionTitle, target === "nearby" && styles.activeText]}>
            Nearby People
          </Text>
          <Text style={styles.optionSub}>Within 2km radius</Text>
        </TouchableOpacity>
      </View>

      {target === "friends" && (
        <Pressable onPress={() => router.push("/profile")}>
          <Text style={styles.info}>Manage close friends in settings</Text>
        </Pressable>
      )}

      <Text style={styles.label}>Describe your situation (optional)</Text>

      <TextInput
        style={styles.input}
        placeholder="Tell us what's happening..."
        placeholderTextColor="#999"
        multiline
        value={message}
        onChangeText={setMessage}
        editable={!sending}
      />

      {!locationAllowed && (
        <Text style={styles.warning}>
          Location access needed for emergency alerts
        </Text>
      )}

      {/* PRESS & HOLD */}
<Pressable
  onPressIn={startHold}
  onPressOut={cancelHold}
  disabled={sending}
  style={[
    styles.sosButton,
    holding && styles.sosHolding,
    sending && styles.sosDisabled,
  ]}
>
  <Text style={styles.sosText}>
    {sending ? "Sending SOS..." : "Press & Hold to Send SOS"}
  </Text>
</Pressable>

{/* CANCEL SOS (only when SOS is active or sending) */}
<TouchableOpacity
  style={styles.cancelSOS}
  onPress={cancelSOSAction}
>
  <Text style={styles.cancelText}>Cancel SOS</Text>
</TouchableOpacity>

      {/* CONFIRM MODAL */}
      <Modal transparent visible={confirmVisible} animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.modal}>
            <Text style={styles.modalTitle}>Send Emergency Alert?</Text>
            <Text style={styles.modalText}>
              This will notify trusted contacts immediately.
            </Text>

            <View style={styles.modalRow}>
              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => setConfirmVisible(false)}
              >
                <Text>Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.confirmBtn} onPress={sendSOS}>
                <Text style={{ color: "#fff" }}>Send SOS</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: "700",
  },
  subtitle: {
    fontSize: 14,
    color: "#666",
    marginBottom: 24,
  },
  label: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 12,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  option: {
    width: "48%",
    borderWidth: 1,
    borderRadius: 14,
    padding: 14,
  },
  active: {
    backgroundColor: "#000",
  },
  optionTitle: {
    fontSize: 16,
    fontWeight: "600",
  },
  activeText: {
    color: "#fff",
  },
  optionSub: {
    fontSize: 12,
    color: "#777",
    marginTop: 6,
  },
  info: {
    fontSize: 13,
    color: "#666",
    marginVertical: 16,
  },
  input: {
    borderWidth: 1,
    borderRadius: 14,
    padding: 14,
    height: 110,
    marginBottom: 14,
    textAlignVertical: "top",
  },
  warning: {
    fontSize: 13,
    color: "#888",
    marginBottom: 20,
  },
  sosButton: {
    backgroundColor: "#d32f2f",
    paddingVertical: 18,
    borderRadius: 20,
    alignItems: "center",
    marginTop: "auto",
    paddingBottom: 20,
  },
  sosHolding: {
    opacity: 0.7,
  },
  sosDisabled: {
    opacity: 0.5,
  },
  sosText: {
    color: "#fff",
    fontWeight: "700",
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.4)",
    justifyContent: "center",
    alignItems: "center",
  },
  modal: {
    width: "85%",
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 20,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: "700",
    marginBottom: 8,
  },
  modalText: {
    fontSize: 14,
    color: "#666",
    marginBottom: 20,
  },
  modalRow: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  cancelBtn: {
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    width: "45%",
    alignItems: "center",
  },
  confirmBtn: {
    padding: 12,
    borderRadius: 12,
    backgroundColor: "#d32f2f",
    width: "45%",
    alignItems: "center",
  },
  cancelSOS: {
    marginBottom: 16,
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#d32f2f",
    alignItems: "center",
  },
  cancelText: {
    color: "#d32f2f",
    fontWeight: "600",
  },
});
