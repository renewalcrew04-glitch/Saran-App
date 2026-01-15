import AsyncStorage from "@react-native-async-storage/async-storage";

const KEY = "pending_uploads";

export async function savePendingUpload(data: any) {
  const existing = await AsyncStorage.getItem(KEY);
  const list = existing ? JSON.parse(existing) : [];
  list.push(data);
  await AsyncStorage.setItem(KEY, JSON.stringify(list));
}

export async function consumePendingUploads() {
  const existing = await AsyncStorage.getItem(KEY);
  await AsyncStorage.removeItem(KEY);
  return existing ? JSON.parse(existing) : [];
}
