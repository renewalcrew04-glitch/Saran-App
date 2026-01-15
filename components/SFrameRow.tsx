import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  Animated,
} from "react-native";
import { useEffect, useRef, useState, useMemo } from "react";
import { useRouter } from "expo-router";
import { useAuthReady } from "@/hooks/useAuthReady";
import { doc, getDoc } from "firebase/firestore";
import { Colors } from "@constants/colors";
import { Spacing } from "@constants/spacing";
import { subscribeActiveSFrames, SFrame } from "@/services/sframes";
import { db } from "@/services/firebase";

/* ---------------- PROFILE CACHE TYPE ---------------- */
type Profile = {
  name: string;
  photoURL: string;
};

const CARD_SIZE = 96;
const CARD_HEIGHT = CARD_SIZE + 20;

export default function SFrameRow() {
  const router = useRouter();
  const user = useAuthReady();

  const [frames, setFrames] = useState<SFrame[]>([]);
  const [profiles, setProfiles] = useState<Record<string, Profile>>({});
  const scaleAnim = useRef(new Animated.Value(1)).current;

  /* 🔴 REAL-TIME S-FRAMES */
  useEffect(() => {
    if (!user) return;
    return subscribeActiveSFrames(setFrames);
  }, [user?.uid]);

  /* 🔴 GROUP → ONE FRAME PER USER (LATEST ONLY) */
  const latestFramesByUser = useMemo(() => {
  const map = new Map<string, SFrame>();
  const now = Date.now();
  const DAY = 24 * 60 * 60 * 1000;

  for (const frame of frames) {
    if (
      !frame.createdAt ||
      now - frame.createdAt.toMillis() > DAY
    ) {
      continue; // ❌ skip older than 24h
    }

    const existing = map.get(frame.uid);

    if (
      !existing ||
      frame.createdAt.toMillis() >
        existing.createdAt.toMillis()
    ) {
      map.set(frame.uid, frame);
    }
  }

  return Array.from(map.values());
}, [frames]);

  /* 🔴 LOAD PROFILES */
  useEffect(() => {
    if (!user || latestFramesByUser.length === 0) return;

    const loadProfiles = async () => {
      const missing = latestFramesByUser
        .map((f) => f.uid)
        .filter((id) => !profiles[id]);

      const updates: Record<string, Profile> = {};

      for (const id of missing) {
        const snap = await getDoc(doc(db, "profiles", id));
        if (snap.exists()) {
          const data = snap.data();
          updates[id] = {
            name: data.name,
            photoURL: data.photoURL,
          };
        }
      }

      if (Object.keys(updates).length) {
        setProfiles((p) => ({ ...p, ...updates }));
      }
    };

    loadProfiles();
  }, [latestFramesByUser, user?.uid]);

  useEffect(() => {
    Animated.spring(scaleAnim, {
      toValue: 1,
      useNativeDriver: true,
    }).start();
  }, [latestFramesByUser]);

  if (!user) return null;
  const uid = user.uid;

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.container}
    >
      {/* ➕ ADD S-FRAME */}
      <TouchableOpacity
        onPress={() => router.push("/sframe/create")}
        style={styles.item}
        activeOpacity={0.8}
      >
        <View style={[styles.card, styles.addCard]}>
          <Text style={styles.plus}>＋</Text>
          <Text style={styles.addText}>Add S-Frame</Text>
        </View>
      </TouchableOpacity>

      {/* ONE CARD PER USER */}
      {latestFramesByUser.map((item) => {
        const profile = profiles[item.uid];
        const seen = item.views?.includes(uid);

        return (
          <TouchableOpacity
            key={item.uid} // 🔥 one per user
            onPress={() =>
  router.push({
    pathname: "/sframe/view/[id]",
    params: {
      id: item.uid,
      order: latestFramesByUser
        .map((f) => f.uid)
        .join(","),
    },
  })
}
            style={styles.item}
            activeOpacity={0.85}
          >
            <Animated.View
              style={[
                styles.card,
                styles.shadow,
                seen ? styles.seenCard : styles.unseenCard,
                {
                  transform: [{ scale: seen ? 0.96 : 1 }],
                  opacity: seen ? 0.7 : 1,
                },
              ]}
            >
              <View style={styles.previewWrap}>
                {profile?.photoURL ? (
                  <Image
                    source={{ uri: profile.photoURL }}
                    style={styles.preview}
                  />
                ) : (
                  <View style={styles.preview} />
                )}
              </View>

              <Text style={styles.name} numberOfLines={1}>
                {profile?.name || ""}
              </Text>
            </Animated.View>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    gap: Spacing.md,
  },

  item: {
    width: CARD_SIZE,
  },

  card: {
    height: CARD_HEIGHT,
    borderRadius: 18,
    backgroundColor: Colors.white,
    alignItems: "center",
    paddingTop: 12,
    overflow: "hidden",
  },

  addCard: {
    borderWidth: 1,
    borderStyle: "dashed",
    borderColor: Colors.gray500,
    justifyContent: "center",
    paddingTop: 0,
  },

  unseenCard: {
    borderWidth: 2,
    borderColor: Colors.black,
  },

  seenCard: {
    borderWidth: 2,
    borderColor: Colors.gray300,
  },

  previewWrap: {
    marginBottom: 8,
  },

  preview: {
    width: 52,
    height: 52,
    borderRadius: 14,
    backgroundColor: Colors.gray300,
  },

  name: {
    fontSize: 12,
    fontWeight: "500",
    color: Colors.black,
    textAlign: "center",
  },

  shadow: {
    shadowColor: "#000",
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 3,
  },

  plus: {
    fontSize: 28,
    color: Colors.black,
    marginBottom: 4,
  },

  addText: {
    fontSize: 11,
    color: Colors.gray700,
  },
});
