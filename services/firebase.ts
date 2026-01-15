import { initializeApp, getApps, getApp } from "firebase/app";
import {
  initializeAuth,
  getAuth,
  browserLocalPersistence,
} from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";
import AsyncStorage from "@react-native-async-storage/async-storage";

const firebaseConfig = {
  apiKey: "AIzaSyD2WvWyKUGeYRkiy45g0HmwYz9elmxlH3E",
  authDomain: "saran-app-1.firebaseapp.com",
  projectId: "saran-app-1",
  storageBucket: "saran-app-1.appspot.com",
  messagingSenderId: "937954035894",
  appId: "1:937954035894:web:ce73f3510700cd8b3d3e17",
};

export const app =
  getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();

/**
 * ✅ Expo-compatible auth
 * ✅ Persists session
 * ❌ No firebase/auth/react-native import
 */
export const auth =
  getApps().length === 1
    ? initializeAuth(app, {
        persistence: browserLocalPersistence,
      })
    : getAuth(app);

export const db = getFirestore(app);
export const storage = getStorage(app);
