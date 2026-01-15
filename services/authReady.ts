// services/authReady.ts
import { onAuthStateChanged, User } from "firebase/auth";
import { auth } from "@/services/firebase";

let resolved = false;
let currentUser: User | null = null;
const waiters: ((user: User | null) => void)[] = [];

onAuthStateChanged(auth, (user) => {
  currentUser = user;
  resolved = true;
  waiters.forEach((cb) => cb(user));
});

export function waitForAuth(): Promise<User | null> {
  if (resolved) return Promise.resolve(currentUser);

  return new Promise((resolve) => {
    waiters.push(resolve);
  });
}
