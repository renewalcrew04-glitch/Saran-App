import { View, Text, Linking, StyleSheet, TouchableOpacity } from "react-native";
import { useRouter } from "expo-router";

export default function Settings() {
  const router = useRouter();

  const Item = ({ label, path }: { label: string; path: string }) => (
    <TouchableOpacity
      style={styles.item}
      onPress={() => router.push(path)}
    >
      <Text style={styles.text}>{label}</Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <Item label="Notifications" path="/profile/settings/notifications" />
      <Item label="Account Privacy" path="/profile/settings/privacy" />
      <Item label="Close Friends" path="/profile/settings/close-friends" />
      <Item label="Blocked" path="/profile/settings/blocked" />
      <Item label="Muted Accounts" path="/profile/settings/muted" />
      <Item label="Comments" path="/profile/settings/comments" />
      <Item label="S-frame" path="/profile/settings/sframe" />
      <Item label="Direct Messages" path="/profile/settings/dm" />
      <Item label="Like & Share Counts" path="/profile/settings/likes" />
      <Item label="Language" path="/profile/settings/language" />

      {/* ✅ Terms & Policies */}
      <TouchableOpacity
        style={styles.item}
        onPress={() =>
          Linking.openURL("https://www.saranapp.com/policies.html")
        }
      >
        <Text style={styles.text}>Terms & Policies</Text>
      </TouchableOpacity>

      <View style={styles.divider} />

      <Item label="Delete Account" path="/profile/settings/delete-account" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    paddingTop: 12,
  },
  item: {
    paddingVertical: 16,
    paddingHorizontal: 20,
  },
  text: {
    fontSize: 16,
    color: "#000",
  },
  divider: {
    height: 1,
    backgroundColor: "#eee",
    marginVertical: 8,
  },
});
