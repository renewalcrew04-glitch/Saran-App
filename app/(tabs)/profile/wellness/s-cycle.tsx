import React, { useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
  ScrollView,
} from "react-native";
import { useRouter } from "expo-router";
import {
  format,
  addDays,
  differenceInDays,
  startOfDay,
} from "date-fns";

/* ---------------- CONSTANTS ---------------- */
const CYCLE_LENGTH = 28;
const OVULATION_DAY = 14;

const symptoms = [
  "Cramps",
  "Headache",
  "Bloating",
  "Cravings",
  "Fatigue",
  "Back Pain",
  "Mood Swings",
];

const moods = [
  { value: "happy", emoji: "😊" },
  { value: "calm", emoji: "😌" },
  { value: "anxious", emoji: "😰" },
  { value: "sad", emoji: "😢" },
  { value: "irritable", emoji: "😤" },
  { value: "tired", emoji: "😴" },
  { value: "energetic", emoji: "⚡" },
];

const tips = [
  "Stay hydrated with warm water",
  "Iron-rich foods help during periods",
  "Gentle stretching can ease cramps",
  "Rest is productive — listen to your body",
  "Magnesium helps reduce discomfort",
];

/* ---------------- HELPERS ---------------- */
function getNextPeriodDate(lastPeriodStart: Date | null) {
  if (!lastPeriodStart) return null;
  return addDays(lastPeriodStart, CYCLE_LENGTH);
}

function getFertilityWindow(lastPeriodStart: Date | null) {
  if (!lastPeriodStart) return null;

  const ovulation = addDays(lastPeriodStart, OVULATION_DAY);
  return {
    start: addDays(ovulation, -5),
    end: addDays(ovulation, 1),
  };
}

function getDaysUntilPeriod(nextPeriod: Date | null) {
  if (!nextPeriod) return null;
  return differenceInDays(nextPeriod, startOfDay(new Date()));
}

/* ---------------- SCREEN ---------------- */
export default function SCycle() {
  const router = useRouter();

  const [lastPeriodStart, setLastPeriodStart] = useState<Date | null>(null);
  const [lastPeriodEnd, setLastPeriodEnd] = useState<Date | null>(null);

  const [showDialog, setShowDialog] = useState(false);
  const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>([]);
  const [selectedMood, setSelectedMood] = useState<string | null>(null);

  const nextPeriod = getNextPeriodDate(lastPeriodStart);
  const fertilityWindow = getFertilityWindow(lastPeriodStart);
  const daysUntilPeriod = getDaysUntilPeriod(nextPeriod);

  const cycleDay = lastPeriodStart
    ? differenceInDays(new Date(), lastPeriodStart) + 1
    : null;

  const isOnPeriod =
    lastPeriodStart &&
    (!lastPeriodEnd || lastPeriodEnd < lastPeriodStart);

  /* -------- Actions -------- */
  const logPeriodStart = () => {
    setLastPeriodStart(new Date());
    setLastPeriodEnd(null);
  };

  const logPeriodEnd = () => {
    setLastPeriodEnd(new Date());
  };

  const saveLog = () => {
    setSelectedMood(null);
    setSelectedSymptoms([]);
    setShowDialog(false);
  };

  /* ---------------- UI ---------------- */
  return (
    <ScrollView style={styles.container}>
      <TouchableOpacity onPress={() => router.back()}>
        <Text style={styles.back}>← Cycle</Text>
      </TouchableOpacity>

      {/* Cycle Circle */}
      <View style={styles.circleWrap}>
        <View style={styles.circle}>
          {isOnPeriod ? (
            <>
              <Text style={styles.circleTitle}>Period</Text>
              <Text style={styles.circleSub}>Day {cycleDay ?? "—"}</Text>
            </>
          ) : (
            <>
              <Text style={styles.circleNumber}>
                {daysUntilPeriod ?? "—"}
              </Text>
              <Text style={styles.circleSub}>days until period</Text>
            </>
          )}
        </View>
      </View>

      <Text style={styles.tip}>
        {isOnPeriod
          ? "Take care of yourself today."
          : "Your body is strong."}
      </Text>

      {/* Actions */}
      <View style={styles.actions}>
        {!isOnPeriod ? (
          <ActionButton text="Period Started" onPress={logPeriodStart} />
        ) : (
          <ActionButton text="Period Ended" onPress={logPeriodEnd} />
        )}
        <ActionButton text="Log Symptoms" onPress={() => setShowDialog(true)} />
      </View>

      {/* Predictions */}
      {nextPeriod && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Predictions</Text>

          <Row label="Next Period" value={format(nextPeriod, "MMM d")} />

          {fertilityWindow && (
            <Row
              label="Fertility Window"
              value={`${format(
                fertilityWindow.start,
                "MMM d"
              )} - ${format(fertilityWindow.end, "MMM d")}`}
            />
          )}
        </View>
      )}

      {/* Tip */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Wellness Tip</Text>
        <Text style={styles.tipText}>
          {tips[new Date().getDate() % tips.length]}
        </Text>
      </View>

      {/* Log Modal */}
      <Modal visible={showDialog} transparent animationType="slide">
        <View style={styles.modalBg}>
          <View style={styles.modal}>
            <Text style={styles.modalTitle}>Log Today</Text>

            <Text style={styles.sectionTitle}>Mood</Text>
            <View style={styles.wrap}>
              {moods.map((m) => (
                <Pill
                  key={m.value}
                  label={m.emoji}
                  active={selectedMood === m.value}
                  onPress={() =>
                    setSelectedMood(
                      selectedMood === m.value ? null : m.value
                    )
                  }
                />
              ))}
            </View>

            <Text style={styles.sectionTitle}>Symptoms</Text>
            <View style={styles.wrap}>
              {symptoms.map((s) => (
                <Pill
                  key={s}
                  label={s}
                  active={selectedSymptoms.includes(s)}
                  onPress={() =>
                    setSelectedSymptoms((prev) =>
                      prev.includes(s)
                        ? prev.filter((i) => i !== s)
                        : [...prev, s]
                    )
                  }
                />
              ))}
            </View>

            <TouchableOpacity style={styles.saveBtn} onPress={saveLog}>
              <Text style={{ color: "#fff" }}>Save</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
}

/* ---------------- COMPONENTS ---------------- */
const ActionButton = ({ text, onPress }: any) => (
  <TouchableOpacity style={styles.actionBtn} onPress={onPress}>
    <Text>{text}</Text>
  </TouchableOpacity>
);

const Row = ({ label, value }: any) => (
  <View style={styles.row}>
    <Text style={styles.gray}>{label}</Text>
    <Text>{value}</Text>
  </View>
);

const Pill = ({ label, active, onPress }: any) => (
  <TouchableOpacity
    onPress={onPress}
    style={[styles.pill, active && styles.pillActive]}
  >
    <Text style={active && { color: "#fff" }}>{label}</Text>
  </TouchableOpacity>
);

/* ---------------- STYLES ---------------- */
const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#fff", padding: 20 },
  back: { fontSize: 16, marginBottom: 20 },

  circleWrap: { alignItems: "center", marginBottom: 20 },
  circle: {
    width: 180,
    height: 180,
    borderRadius: 90,
    borderWidth: 6,
    alignItems: "center",
    justifyContent: "center",
  },
  circleNumber: { fontSize: 36, fontWeight: "300" },
  circleTitle: { fontSize: 20 },
  circleSub: { fontSize: 12, color: "#666" },

  tip: {
    textAlign: "center",
    fontStyle: "italic",
    marginBottom: 20,
    color: "#555",
  },

  actions: { flexDirection: "row", gap: 12, marginBottom: 20 },
  actionBtn: {
    flex: 1,
    borderWidth: 1,
    borderRadius: 14,
    height: 50,
    alignItems: "center",
    justifyContent: "center",
  },

  card: {
    backgroundColor: "#f7f7f7",
    padding: 16,
    borderRadius: 16,
    marginBottom: 20,
  },
  cardTitle: { fontWeight: "600", marginBottom: 10 },
  row: { flexDirection: "row", justifyContent: "space-between" },
  gray: { color: "#666" },
  tipText: { color: "#555" },

  modalBg: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.4)",
    justifyContent: "center",
    padding: 20,
  },
  modal: {
    backgroundColor: "#fff",
    borderRadius: 20,
    padding: 20,
  },
  modalTitle: { fontSize: 18, marginBottom: 10 },
  sectionTitle: { marginTop: 10, marginBottom: 6 },

  wrap: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  pill: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
  },
  pillActive: {
    backgroundColor: "#000",
    borderColor: "#000",
  },

  saveBtn: {
    marginTop: 20,
    backgroundColor: "#000",
    padding: 14,
    borderRadius: 30,
    alignItems: "center",
  },
});
