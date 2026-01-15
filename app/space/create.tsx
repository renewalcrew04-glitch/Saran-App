import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  Switch,
  StyleSheet,
  Modal,
  Image,
  Alert,
} from "react-native";
import { useState } from "react";
import { Ionicons } from "@expo/vector-icons";
import DateTimePicker from "@react-native-community/datetimepicker";
import * as ImagePicker from "expo-image-picker";

/* ------------------ CONSTANTS ------------------ */

const CATEGORY_OPTIONS = [
  "Meetup",
  "Workshop",
  "Fitness",
  "Art & Craft",
  "Wellness",
  "Food & Dining",
  "Travel & Outdoor",
  "Learning",
  "Social",
  "Others",
];

const CURRENCIES = ["₹ INR", "USD", "EUR"];

/* ------------------ SCREEN ------------------ */

export default function CreateEventScreen() {
  const [cover, setCover] = useState<string | null>(null);

  const [category, setCategory] = useState("Meetup");
  const [showCategory, setShowCategory] = useState(false);

  const [date, setDate] = useState<Date | null>(null);
  const [showDatePicker, setShowDatePicker] = useState(false);

  const [startTime, setStartTime] = useState<Date | null>(null);
  const [endTime, setEndTime] = useState<Date | null>(null);
  const [showStartPicker, setShowStartPicker] = useState(false);
  const [showEndPicker, setShowEndPicker] = useState(false);

  const [location, setLocation] = useState("");
  const [price, setPrice] = useState("");
  const [currency, setCurrency] = useState("₹ INR");

  const [instructions, setInstructions] = useState("");
  const [faqs, setFaqs] = useState([{ q: "", a: "" }]);

  const today = new Date();

  /* ---------- IMAGE PICKER ---------- */
  async function pickImage() {
    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.8,
    });

    if (!res.canceled) {
      setCover(res.assets[0].uri);
    }
  }

  /* ---------- TIME HELPERS ---------- */
  function handleStartTime(d?: Date) {
    if (!d) return;
    setStartTime(d);

    const autoEnd = new Date(d);
    autoEnd.setHours(autoEnd.getHours() + 1);
    setEndTime(autoEnd);
  }

  function handleEndTime(d?: Date) {
    if (!d || !startTime) return;

    if (d <= startTime) {
      Alert.alert("Invalid Time", "End time must be after start time");
      return;
    }
    setEndTime(d);
  }

  /* ------------------ UI ------------------ */

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.pageTitle}>Create Event</Text>

      {/* Cover */}
      <Pressable style={styles.cover} onPress={pickImage}>
        {cover ? (
          <Image source={{ uri: cover }} style={styles.coverImg} />
        ) : (
          <>
            <Ionicons name="image-outline" size={28} color="#999" />
            <Text style={styles.coverText}>Add cover image</Text>
          </>
        )}
      </Pressable>

      <Section title="Event Details" />

      <Label text="Title *" />
      <Input placeholder="Event title" />

      <Label text="Category" />
      <Pressable style={styles.dropdown} onPress={() => setShowCategory(true)}>
        <Text>{category}</Text>
        <Ionicons name="chevron-down" />
      </Pressable>

      <Label text="Description" />
      <Input multiline height={90} placeholder="Tell people about your event..." />

      <Section title="Date & Time" />

      <Label text="Date *" />
      <Pressable style={styles.dropdown} onPress={() => setShowDatePicker(true)}>
        <Text>{date ? formatDate(date) : "dd/mm/yyyy"}</Text>
        <Ionicons name="calendar-outline" />
      </Pressable>

      <View style={styles.row}>
        <View style={{ flex: 1 }}>
          <Label text="Start Time *" />
          <Pressable
            style={styles.dropdown}
            onPress={() => setShowStartPicker(true)}
          >
            <Text>{startTime ? formatTime(startTime) : "--:-- --"}</Text>
            <Ionicons name="time-outline" />
          </Pressable>
        </View>

        <View style={{ width: 12 }} />

        <View style={{ flex: 1 }}>
          <Label text="End Time" />
          <Pressable
            style={styles.dropdown}
            onPress={() => setShowEndPicker(true)}
          >
            <Text>{endTime ? formatTime(endTime) : "--:-- --"}</Text>
            <Ionicons name="time-outline" />
          </Pressable>
        </View>
      </View>

      <Section title="Location" />
      <Input value={location} onChangeText={setLocation} placeholder="Event location" />

      <Section title="Slots & Pricing" />

      <Label text="Price per slot" />
      <View style={styles.row}>
        <Input
          value={price}
          onChangeText={setPrice}
          keyboardType="numeric"
          placeholder="0"
          style={{ flex: 1 }}
        />
        <View style={{ width: 12 }} />
        <Pressable
          style={[styles.dropdown, { flex: 1 }]}
          onPress={() =>
            setCurrency(
              CURRENCIES[(CURRENCIES.indexOf(currency) + 1) % CURRENCIES.length]
            )
          }
        >
          <Text>{currency}</Text>
          <Ionicons name="chevron-down" />
        </Pressable>
      </View>

      <Section title="Instructions for Participants" />
      <Input
        multiline
        height={80}
        value={instructions}
        onChangeText={setInstructions}
        placeholder="What to bring, rules, etc."
      />

      <Section title="FAQs" />
      {faqs.map((f, i) => (
        <View key={i}>
          <Input
            placeholder="Question"
            value={f.q}
            onChangeText={(t: string) => {
              const n = [...faqs];
              n[i].q = t;
              setFaqs(n);
            }}
          />
          <Input
            placeholder="Answer (optional)"
            value={f.a}
            onChangeText={(v: string) => {
              const n = [...faqs];
              n[i].a = v;
              setFaqs(n);
            }}
          />
        </View>
      ))}
      <Pressable onPress={() => setFaqs([...faqs, { q: "", a: "" }])}>
        <Text style={styles.addFaq}>+ Add FAQ</Text>
      </Pressable>

      <Section title="Video (Optional)" />
      <Pressable style={styles.video}>
        <Ionicons name="videocam-outline" size={20} />
        <Text>Add video</Text>
      </Pressable>

      <Pressable style={styles.submit}>
        <Text style={styles.submitText}>Create Event</Text>
      </Pressable>

      {/* ---------- MODALS ---------- */}
      <Modal visible={showCategory} transparent animationType="fade">
        <Pressable
          style={styles.modalOverlay}
          onPress={() => setShowCategory(false)}
        >
          <View style={styles.modal}>
            {CATEGORY_OPTIONS.map((c) => (
              <Pressable key={c} style={styles.option} onPress={() => {
                setCategory(c);
                setShowCategory(false);
              }}>
                <Text>{c}</Text>
              </Pressable>
            ))}
          </View>
        </Pressable>
      </Modal>

      {showDatePicker && (
        <DateTimePicker
          value={date || today}
          minimumDate={today}
          mode="date"
          onChange={(_, d) => {
            setShowDatePicker(false);
            if (d) setDate(d);
          }}
        />
      )}

      {showStartPicker && (
        <DateTimePicker
          value={startTime || today}
          mode="time"
          onChange={(_, d) => {
            setShowStartPicker(false);
            handleStartTime(d);
          }}
        />
      )}

      {showEndPicker && (
        <DateTimePicker
          value={endTime || today}
          mode="time"
          onChange={(_, d) => {
            setShowEndPicker(false);
            handleEndTime(d);
          }}
        />
      )}
    </ScrollView>
  );
}

/* ------------------ HELPERS ------------------ */

function Section({ title }: { title: string }) {
  return <Text style={styles.section}>{title}</Text>;
}

function Label({ text }: { text: string }) {
  return <Text style={styles.label}>{text}</Text>;
}

function Input(props: any) {
  return (
    <TextInput
      {...props}
      style={[
        styles.input,
        props.height ? { height: props.height, textAlignVertical: "top" } : null,
      ]}
      placeholderTextColor="#999"
    />
  );
}

function formatDate(d: Date) {
  return `${String(d.getDate()).padStart(2, "0")}/${String(
    d.getMonth() + 1
  ).padStart(2, "0")}/${d.getFullYear()}`;
}

function formatTime(d: Date) {
  let h = d.getHours();
  const m = String(d.getMinutes()).padStart(2, "0");
  const ap = h >= 12 ? "PM" : "AM";
  h = h % 12 || 12;
  return `${h}:${m} ${ap}`;
}

/* ------------------ STYLES ------------------ */

const styles = StyleSheet.create({
  container: { padding: 16, paddingBottom: 40, backgroundColor: "#fff" },
  pageTitle: { fontSize: 20, fontWeight: "600", marginBottom: 16 },
  cover: {
    height: 160,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#DDD",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 24,
    overflow: "hidden",
  },
  coverImg: { width: "100%", height: "100%" },
  coverText: { marginTop: 6, color: "#666" },
  section: { fontSize: 14, fontWeight: "600", marginTop: 24, marginBottom: 8 },
  label: { fontSize: 13, color: "#444", marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderColor: "#E5E5E5",
    borderRadius: 10,
    padding: 12,
    fontSize: 14,
    marginBottom: 10,
  },
  dropdown: {
    flexDirection: "row",
    justifyContent: "space-between",
    borderWidth: 1,
    borderColor: "#E5E5E5",
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
  },
  row: { flexDirection: "row" },
  addFaq: { marginTop: 8, fontWeight: "500" },
  video: {
    height: 44,
    borderWidth: 1,
    borderColor: "#E5E5E5",
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
    flexDirection: "row",
    gap: 6,
  },
  submit: {
    backgroundColor: "#000",
    padding: 16,
    borderRadius: 14,
    alignItems: "center",
    marginTop: 32,
  },
  submitText: { color: "#fff", fontWeight: "600" },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.3)",
    justifyContent: "center",
    padding: 24,
  },
  modal: { backgroundColor: "#fff", borderRadius: 14 },
  option: {
    padding: 14,
    borderBottomWidth: 1,
    borderColor: "#EEE",
  },
});
