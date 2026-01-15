import { View, Text, Image, StyleSheet } from "react-native";
import { Timestamp } from "firebase/firestore";
import { formatPostTime } from "@/utils/formatPostTime";

export default function PostHeader({
  name,
  avatar,
  createdAt,
}: {
  name: string;
  avatar?: string;
  createdAt: Timestamp;
}) {
  return (
    <View style={styles.row}>
      {/* AVATAR */}
      <Image
        source={{
          uri:
            avatar ||
            "https://ui-avatars.com/api/?name=User",
        }}
        style={styles.avatar}
      />

      {/* NAME + TIME */}
      <View style={styles.center}>
        <Text style={styles.name} numberOfLines={1}>
          {name}
        </Text>

        <Text style={styles.time}>
          {formatPostTime(createdAt)}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 8,
  },

  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    marginRight: 10,
  },

  center: {
    flex: 1,
  },

  name: {
    fontWeight: "600",
    fontSize: 14,
  },

  time: {
    fontSize: 11,
    color: "#777",
    marginTop: 2,
  },
});
