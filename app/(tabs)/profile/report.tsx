import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from "react-native";
import { useState } from "react";
import { auth, db } from "@/services/firebase";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { Ionicons } from "@expo/vector-icons";

const PROBLEM_TYPES = [
  { key: "bug", label: "App not working properly" },
  { key: "crash", label: "App crashed or froze" },
  { key: "login", label: "Login / OTP issue" },
  { key: "account", label: "Account or profile issue" },
  { key: "content", label: "Post, comment, or message issue" },
  { key: "men_spotted", label: "Spotted men on the app" },
  { key: "harassment", label: "Harassment or unsafe behavior" },
  { key: "privacy", label: "Privacy or safety concern" },
  { key: "other", label: "Something else" },
];

export default function ReportProblem() {
  const [type, setType] = useState<{ key: string; label: string } | null>(null);
  const [open, setOpen] = useState(false);
  const [text, setText] = useState("");

  const submit = async () => {
    if (!type) {
      Alert.alert("Please select a problem type");
      return;
    }

    if (!text.trim()) {
      Alert.alert("Please describe the issue");
      return;
    }

    await addDoc(collection(db, "reports"), {
      uid: auth.currentUser?.uid,
      type: type.key,
      message: text.trim(),
      status: "open",
      createdAt: serverTimestamp(),
    });

    Alert.alert("Thank you", "We’ve received your report.");
    setType(null);
    setText("");
    setOpen(false);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Report a problem</Text>

      {/* Dropdown */}
      <Text style={styles.section}>What went wrong?</Text>

      <TouchableOpacity
        style={styles.dropdown}
        onPress={() => setOpen(!open)}
        activeOpacity={0.8}
      >
        <Text style={type ? styles.dropdownText : styles.placeholder}>
          {type ? type.label : "Select a problem"}
        </Text>

        <Ionicons
          name={open ? "chevron-up" : "chevron-down"}
          size={18}
          color="#666"
        />
      </TouchableOpacity>

      {open && (
        <View style={styles.dropdownList}>
          {PROBLEM_TYPES.map((item) => (
            <TouchableOpacity
              key={item.key}
              style={styles.dropdownItem}
              onPress={() => {
                setType(item);
                setOpen(false);
              }}
            >
              <Text style={styles.dropdownItemText}>{item.label}</Text>
            </TouchableOpacity>
          ))}
        </View>
      )}

      {/* Message */}
      {type && (
        <>
          <Text style={styles.section}>Describe the issue</Text>
          <TextInput
            value={text}
            onChangeText={setText}
            placeholder="Tell us what happened…"
            multiline
            style={styles.input}
          />
        </>
      )}

      {/* Submit */}
      <TouchableOpacity style={styles.btn} onPress={submit}>
        <Text style={styles.btnText}>Submit</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#fff",
  },
  title: {
    fontSize: 20,
    fontWeight: "600",
    marginBottom: 16,
  },
  section: {
    marginTop: 18,
    marginBottom: 8,
    fontSize: 14,
    fontWeight: "500",
  },

  /* Dropdown */
  dropdown: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#ddd",
    backgroundColor: "#fafafa",
  },
  dropdownText: {
    fontSize: 14,
    color: "#000",
  },
  placeholder: {
    fontSize: 14,
    color: "#888",
  },
  dropdownList: {
    marginTop: 6,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#ddd",
    backgroundColor: "#fff",
    overflow: "hidden",
  },
  dropdownItem: {
    padding: 14,
    borderBottomWidth: 0.5,
    borderColor: "#eee",
  },
  dropdownItemText: {
    fontSize: 14,
    color: "#000",
  },

  /* Input */
  input: {
    minHeight: 120,
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 12,
    padding: 12,
    textAlignVertical: "top",
    backgroundColor: "#fafafa",
  },

  /* Button */
  btn: {
    marginTop: 24,
    backgroundColor: "#000",
    padding: 14,
    borderRadius: 12,
    alignItems: "center",
  },
  btnText: {
    color: "#fff",
    fontWeight: "600",
  },
});
