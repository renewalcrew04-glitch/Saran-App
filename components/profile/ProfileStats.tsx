import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { useRouter } from "expo-router";

export default function ProfileStats({
  uid,
  followers,
  following,
}: {
  uid: string;
  followers: number;
  following: number;
}) {
  const router = useRouter();

  return (
    <View style={styles.row}>
      <TouchableOpacity
        style={styles.item}
        onPress={() =>
          router.push(`/profile/followers?uid=${uid}`)
        }
      >
        <Text style={styles.count}>{followers}</Text>
        <Text style={styles.label}>Followers</Text>
      </TouchableOpacity>
        
      <TouchableOpacity
        style={styles.item}
        onPress={() =>
          router.push(`/profile/following?uid=${uid}`)
        }
      >
        <Text style={styles.count}>{following}</Text>
        <Text style={styles.label}>Following</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    justifyContent: "space-around",
    flex: 2,
  },
  item: {
    alignItems: "center",
  },
  count: {
    fontSize: 16,
    fontWeight: "700",
  },
  label: {
    fontSize: 12,
    color: "#666",
    marginTop: 2,
  },
});

