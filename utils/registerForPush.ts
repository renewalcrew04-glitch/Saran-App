import Constants from "expo-constants";

/**
 * Push registration
 * HARD DISABLED in Expo Go (SDK 53+)
 */
export async function registerForPush(): Promise<string | null> {
  // 🚫 Expo Go CANNOT even import expo-notifications
  if (Constants.appOwnership === "expo") {
    console.log(
      "Expo Go detected – push notifications skipped"
    );
    return null;
  }

  // ✅ Dynamically import ONLY in dev build / production
  const Notifications = await import("expo-notifications");
  const { Platform } = await import("react-native");

  const { status: existingStatus } =
    await Notifications.getPermissionsAsync();

  let finalStatus = existingStatus;
  if (existingStatus !== "granted") {
    const { status } =
      await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== "granted") {
    return null;
  }

  const tokenResponse =
    await Notifications.getExpoPushTokenAsync();

  if (Platform.OS === "android") {
    await Notifications.setNotificationChannelAsync(
      "default",
      {
        name: "default",
        importance:
          Notifications.AndroidImportance.MAX,
      }
    );
  }

  return tokenResponse.data;
}
