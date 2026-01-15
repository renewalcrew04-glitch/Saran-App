import { View, Text, StyleSheet } from "react-native";
import { useEffect, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Colors } from "@/constants/colors";

const KEY = "pending_uploads";

export default function UploadQueueStatus() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const load = async () => {
      const raw = await AsyncStorage.getItem(KEY);
      const list = raw ? JSON.parse(raw) : [];
      setCount(list.length);
    };

    load();
    const id = setInterval(load, 3000);
    return () => clearInterval(id);
  }, []);

  if (count === 0) return null;

  return (
    <View style={styles.wrap}>
      <Text style={styles.text}>
        ⏳ Uploading {count} item{count > 1 ? "s" : ""}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    backgroundColor: Colors.black,
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 16,
    alignSelf: "center",
    marginVertical: 8,
  },
  text: {
    color: Colors.white,
    fontSize: 12,
  },
});
