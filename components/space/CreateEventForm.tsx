import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  Switch,
  StyleSheet,
} from "react-native";
import { useState } from "react";

export default function CreateEventForm() {
  const [allowMultiple, setAllowMultiple] = useState(false);

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {/* Cover Image */}
      <Pressable style={styles.cover}>
        <Text style={styles.coverText}>Add cover image</Text>
      </Pressable>

      {/* Event Details */}
      <Section title="Event Details" />

      <Label title="Title *" />
      <Input placeholder="Event title" />

      <Label title="Category" />
      <Input placeholder="Meetup" />

      <Label title="Description" />
      <Input
        placeholder="Tell people about your event..."
        multiline
        height={90}
      />

      {/* Date & Time */}
      <Section title="Date & Time" />

      <Label title="Date *" />
      <Input placeholder="mm/dd/yyyy" />

      <Label title="Start Time *" />
      <Input placeholder="--:-- --" />

      <Label title="End Time" />
      <Input placeholder="--:-- --" />

      {/* Location */}
      <Section title="Location" />

      <Label title="Event location or address" />
      <Input placeholder="Location" />

      {/* Slots & Pricing */}
      <Section title="Slots & Pricing" />

      <Label title="Total Slots" />
      <Input placeholder="10" keyboardType="numeric" />

      <View style={styles.switchRow}>
        <Text>Allow multiple bookings per user</Text>
        <Switch value={allowMultiple} onValueChange={setAllowMultiple} />
      </View>

      <Label title="Price per slot" />
      <Input placeholder="0" keyboardType="numeric" />

      <Label title="Currency" />
      <Input placeholder="₹ INR" />

      {/* Instructions */}
      <Section title="Instructions for Participants" />
      <Input
        placeholder="Any special instructions, what to bring, etc."
        multiline
        height={80}
      />

      {/* FAQs */}
      <Section title="FAQs" />
      <Input placeholder="Question" />
      <Input placeholder="Answer (optional)" />
      <Pressable>
        <Text style={styles.add}>+ Add FAQ</Text>
      </Pressable>

      {/* Video */}
      <Section title="Video (Optional)" />
      <Pressable style={styles.video}>
        <Text>Add video</Text>
      </Pressable>

      {/* Submit */}
      <Pressable style={styles.submit}>
        <Text style={styles.submitText}>Create Event</Text>
      </Pressable>
    </ScrollView>
  );
}

/* ---------- Reusable UI ---------- */

function Section({ title }: { title: string }) {
  return <Text style={styles.section}>{title}</Text>;
}

function Label({ title }: { title: string }) {
  return <Text style={styles.label}>{title}</Text>;
}

function Input({
  placeholder,
  multiline,
  keyboardType,
  height,
}: {
  placeholder: string;
  multiline?: boolean;
  keyboardType?: any;
  height?: number;
}) {
  return (
    <TextInput
      placeholder={placeholder}
      placeholderTextColor="#999"
      multiline={multiline}
      keyboardType={keyboardType}
      style={[
        styles.input,
        height ? { height, textAlignVertical: "top" } : null,
      ]}
    />
  );
}

/* ---------- Styles ---------- */

const styles = StyleSheet.create({
  container: {
    padding: 16,
    paddingBottom: 40,
  },
  cover: {
    height: 160,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#DDD",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 20,
  },
  coverText: {
    color: "#666",
  },
  section: {
    fontSize: 14,
    fontWeight: "600",
    marginTop: 24,
    marginBottom: 8,
  },
  label: {
    marginTop: 12,
    marginBottom: 6,
    fontSize: 13,
    color: "#444",
  },
  input: {
    borderWidth: 1,
    borderColor: "#E5E5E5",
    borderRadius: 10,
    padding: 12,
    fontSize: 14,
  },
  switchRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginVertical: 12,
  },
  add: {
    color: "#000",
    marginTop: 8,
    fontWeight: "500",
  },
  video: {
    height: 44,
    borderWidth: 1,
    borderColor: "#E5E5E5",
    borderRadius: 10,
    justifyContent: "center",
    alignItems: "center",
  },
  submit: {
    backgroundColor: "#000",
    marginTop: 30,
    padding: 14,
    borderRadius: 12,
    alignItems: "center",
  },
  submitText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 15,
  },
});
