import { View, Text, TextInput, TouchableOpacity, StyleSheet } from "react-native";
import { useState } from "react";
import { useRouter } from "expo-router";

export default function MindJournal() {
  const router = useRouter();
  const [feeling, setFeeling] = useState("");
  const [fear, setFear] = useState("");
  const [strength, setStrength] = useState("");

  return (
    <View style={styles.container}>
      <Header title="S-Mind Journal" />

      <Question label="What color represents your mood today?" value={feeling} onChange={setFeeling} />
      <Question label="What fear is holding you back?" value={fear} onChange={setFear} />
      <Question label="What strength did you show today?" value={strength} onChange={setStrength} />

      <TouchableOpacity style={styles.button}>
        <Text style={styles.buttonText}>Save Entry</Text>
      </TouchableOpacity>
    </View>
  );
}

type QuestionProps = {
  label: string;
  value: string;
  onChange: (text: string) => void;
};

function Question({ label, value, onChange }: QuestionProps) {

  return (
    <View style={{ marginBottom: 18 }}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        multiline
        value={value}
        onChangeText={onChange}
        placeholder="Take your time..."
        style={styles.input}
      />
    </View>
  );
}

type HeaderProps = {
  title: string;
};

function Header({ title }: HeaderProps) {

  const router = useRouter();
  return (
    <TouchableOpacity onPress={() => router.back()}>
      <Text style={styles.back}>← {title}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, backgroundColor: "#fff" },
  back: { fontSize: 16, marginBottom: 20 },
  label: { fontSize: 13, color: "#555", marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 14,
    padding: 12,
    minHeight: 70,
  },
  button: {
    backgroundColor: "#000",
    padding: 16,
    borderRadius: 30,
    marginTop: 20,
  },
  buttonText: { color: "#fff", textAlign: "center" },
});
