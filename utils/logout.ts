import { signOut } from "firebase/auth";
import { auth } from "@/services/firebase";
import { useAuthStore } from "@/store/authStore";
import { useProfileStore } from "@/store/profileStore";

export const logout = async () => {
  // Firebase sign out
  await signOut(auth);

  // Reset Zustand stores
  useAuthStore.setState({ user: null });
  await useProfileStore.getState().resetProfile();
};
