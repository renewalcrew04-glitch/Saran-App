import { create } from "zustand";
import { User } from "firebase/auth";

type AuthState = {
  user: User | null | undefined;
  setUser: (user: User | null) => void;
};

export const useAuthStore = create<AuthState>((set) => ({
  user: undefined, // loading
  setUser: (user) => set({ user }),
}));
