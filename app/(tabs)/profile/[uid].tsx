import { auth } from "@/services/firebase";
import { useLocalSearchParams } from "expo-router";

import OwnProfile from "./individual";
import OtherProfile from "@/components/profile/OtherProfile";

export default function ProfileByUid() {
  const { uid } = useLocalSearchParams<{ uid: string }>();
  const currentUid = auth.currentUser?.uid;

  if (!uid || !currentUid) return null;

  // Own profile
  if (uid === currentUid) {
    return <OwnProfile />;
  }

  // Other user's profile
  return <OtherProfile uid={uid} />;
}
