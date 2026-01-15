import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  onSnapshot,
} from "firebase/firestore";
import { db } from "@/services/firebase";

/* ---------------- TYPES ---------------- */

export type VerificationStep = "terms" | "pending" | "verified";

export type ProfileState = {
  /* BASIC */
  name: string;
  email: string;
  age: string;
  city: string;
  phone: string;

  /* PROFILE DISPLAY */
  bio: string;
  location: string;
  website: string;
  avatar: string;
  cover: string;

  profileCompleted: boolean;

  /* VERIFICATION */
  verified: boolean;
  verificationStep: VerificationStep;

  _hydratedUid?: string;

  /* ACTIONS */
  updateProfile: (
    data: Partial<
      Omit<
        ProfileState,
        | "updateProfile"
        | "hydrate"
        | "resetProfile"
        | "startVerificationListener"
      >
    >
  ) => Promise<void>;

  hydrate: (uid: string) => Promise<void>;

  // ✅ IMPORTANT: return unsubscribe
  startVerificationListener: (uid: string) => () => void;

  resetProfile: () => Promise<void>;
};

/* ---------------- STORE ---------------- */

export const useProfileStore = create<ProfileState>()(
  persist(
    (set, get) => ({
      /* DEFAULT STATE */
      name: "",
      email: "",
      age: "",
      city: "",
      phone: "",
      bio: "",
      location: "",
      website: "",
      avatar: "",
      cover: "",

      profileCompleted: false,

      verified: false,
      verificationStep: "terms",

      _hydratedUid: undefined,

      /* UPDATE PROFILE */
      updateProfile: async (data) => {
        const uid = get()._hydratedUid;
        if (!uid) return;

        await updateDoc(doc(db, "profiles", uid), data);
        set((state) => ({ ...state, ...data }));
      },

      /* HYDRATE FROM FIRESTORE */
      hydrate: async (uid) => {
        const currentUid = get()._hydratedUid;

        if (currentUid && currentUid !== uid) {
          set({
            name: "",
            email: "",
            age: "",
            city: "",
            bio: "",
            location: "",
            website: "",
            avatar: "",
            cover: "",
            profileCompleted: false,
            verified: false,
            verificationStep: "terms",
            _hydratedUid: undefined,
          });
        }

        if (get()._hydratedUid === uid) return;

        const ref = doc(db, "profiles", uid);
        const snap = await getDoc(ref);

        if (snap.exists()) {
          const data = snap.data();

          const step: VerificationStep =
            data.verificationStep === "pending" ||
            data.verificationStep === "verified"
              ? data.verificationStep
              : "terms";

          set({
            name: data.name ?? "",
            email: data.email ?? "",
            age: data.age ?? "",
            city: data.city ?? "",

            bio: data.bio ?? "",
            location: data.location ?? "",
            website: data.website ?? "",
            avatar: data.avatar ?? "https://i.pravatar.cc/300",
            cover: data.cover ?? "",

            profileCompleted: data.profileCompleted ?? false,
            verified: data.verified ?? false,
            verificationStep: step,

            _hydratedUid: uid,
          });
        } else {
  // profile does not exist yet – wait for signup flow to create it
  set({
    _hydratedUid: uid,
  });
}
      },

      /* RESET */
      resetProfile: async () => {
        await AsyncStorage.removeItem("saran-profile");

        set({
          name: "",
          email: "",
          age: "",
          city: "",
          bio: "",
          location: "",
          website: "",
          avatar: "",
          cover: "",
          profileCompleted: false,
          verified: false,
          verificationStep: "pending",
          _hydratedUid: undefined,
        });
      },

      /* ✅ VERIFICATION LISTENER */
      startVerificationListener: (uid: string) => {
        const ref = doc(db, "profiles", uid);

        return onSnapshot(ref, (snap) => {
          if (!snap.exists()) return;

          const data = snap.data();

          if (data.verified === true) {
            set({
              verified: true,
              verificationStep: "verified",
            });
          }
        });
      },
    }),
    {
      name: "saran-profile",
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
