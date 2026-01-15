import { Stack } from "expo-router";
import { EventProvider } from "@/components/space/EventStore";
import { useEffect, useState } from "react";
import { doc, updateDoc } from "firebase/firestore";
import { auth, db } from "@/services/firebase";
import { registerForPush } from "@/utils/registerForPush";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { consumePendingUploads, savePendingUpload } from "@/utils/uploadQueue";
import { uploadMediaAsync } from "@/utils/uploadImage";
import { waitForAuth } from "@/services/authReady";
import { View, ActivityIndicator } from "react-native";

export default function RootLayout() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    waitForAuth().then(() => setReady(true));
  }, []);

  useEffect(() => {
  if (!ready) return;

  const resumeUploads = async () => {
    const pending = await consumePendingUploads();

    for (const job of pending) {
      try {
        await uploadMediaAsync(
          job.uri,
          "sframes",
          job.mimeType
        );
      } catch {
        // Put it back if it still fails
        await savePendingUpload(job);
      }
    }
  };

  resumeUploads();
}, [ready]);

  useEffect(() => {
    if (!auth.currentUser) return;

    const savePushToken = async () => {
      const token = await registerForPush();
      if (!token) return;

      await updateDoc(
        doc(db, "profiles", auth.currentUser!.uid),
        { expoPushToken: token }
      );
    };

    savePushToken();
  }, [ready]);

  if (!ready) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <EventProvider>
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="index" />
            <Stack.Screen name="(auth)" />
            <Stack.Screen name="(tabs)" />
            <Stack.Screen name="post/create" />
            <Stack.Screen name="event/create" />
            <Stack.Screen name="event/details" />
          </Stack>
        </EventProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
