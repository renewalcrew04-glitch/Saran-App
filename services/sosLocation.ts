import * as Location from "expo-location";
import { doc, updateDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/services/firebase";

let watcher: Location.LocationSubscription | null =
  null;

export async function startLiveLocation(uid: string) {
  const { status } =
    await Location.requestForegroundPermissionsAsync();
  if (status !== "granted") return;

  watcher = await Location.watchPositionAsync(
    {
      accuracy: Location.Accuracy.High,
      timeInterval: 10000,
      distanceInterval: 10,
    },
    async (loc) => {
      await updateDoc(doc(db, "sos", uid), {
        location: {
          lat: loc.coords.latitude,
          lng: loc.coords.longitude,
        },
        updatedAt: serverTimestamp(),
      });
    }
  );
}

export function stopLiveLocation() {
  watcher?.remove();
  watcher = null;
}
