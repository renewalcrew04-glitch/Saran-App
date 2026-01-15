import {
  View,
  Text,
  StyleSheet,
  Image,
  TouchableOpacity,
} from "react-native";
import { listenToUserReposts } from "@/services/profileReposts";
import type { Post } from "@/types/post";
import ProfileStats from "@/components/profile/ProfileStats";
import { Ionicons } from "@expo/vector-icons";
import { useRouter, useFocusEffect } from "expo-router";
import { useEffect, useState, useCallback } from "react";
import { auth } from "@/services/firebase";
import { listenToUserPosts } from "@/services/posts";
import { useIsFocused } from "@react-navigation/native";
import ProfilePostGrid from "@/components/profile/ProfilePostGrid";
import { useProfileStore } from "@/store/profileStore";
import FallbackAvatar from "@/components/ui/FallbackAvatar";
import CoverPlaceholder from "@components/ui/CoverPlaceholder";
import { useLocalSearchParams } from "expo-router";

import {
  getFollowersCount,
  getFollowingCount,
} from "@/services/followCounts";

/* ---------------- TYPES ---------------- */

type FilterType = "all" | "text" | "photo" | "video" | "repost";

/* ---------------- MAIN SCREEN ---------------- */

export default function IndividualProfile() {

  const router = useRouter();
  const [reposts, setReposts] = useState<Post[]>([]);
  const params = useLocalSearchParams<{ uid?: string }>();
const profileUid = params.uid ?? auth.currentUser?.uid;

  /* ===== STORE ===== */
  const name = useProfileStore((s) => s.name);
const bio = useProfileStore((s) => s.bio);
const location = useProfileStore((s) => s.location);
const website = useProfileStore((s) => s.website);
const avatar = useProfileStore((s) => s.avatar);
const cover = useProfileStore((s) => s.cover);
const hydrate = useProfileStore((s) => s.hydrate);
const [followersCount, setFollowersCount] = useState<number | null>(null);
const [followingCount, setFollowingCount] = useState<number | null>(null);
const isFocused = useIsFocused();

  /* ===== STATE ===== */
  const [activeFilter, setActiveFilter] =
    useState<FilterType>("all");
  const [posts, setPosts] = useState<Post[]>([]);

  useFocusEffect(
  useCallback(() => {
    if (!profileUid) return;

    hydrate(profileUid);

    const unsubPosts = listenToUserPosts(profileUid, setPosts);
    const unsubReposts = listenToUserReposts(profileUid, setReposts);
    getFollowersCount(profileUid).then(setFollowersCount);
    getFollowingCount(profileUid).then(setFollowingCount);

    return () => {
      unsubPosts();
       unsubReposts();
    };
  }, [profileUid, isFocused])
);

useEffect(() => {
  console.log("POSTS:", posts.length);
  console.log("REPOSTS:", reposts.length);
  console.log("ACTIVE FILTER:", activeFilter);
}, [posts, reposts, activeFilter]);

  const filteredPosts =
  activeFilter === "repost"
    ? reposts
    : activeFilter === "all"
    ? posts
    : posts.filter((post) => {
        if (activeFilter === "text") return post.type === "text";
        if (activeFilter === "photo") return post.type === "photo";
        if (activeFilter === "video") return post.type === "video";
        return true;
      });

  return (
  <View style={styles.root}>
    <ProfilePostGrid
      posts={filteredPosts}
      ListHeaderComponent={
        <>
          {/* COVER */}
          <View style={styles.cover}>
            {cover ? (
              <Image source={{ uri: cover }} style={styles.cover} />
            ) : (
              <CoverPlaceholder height={140} />
            )}
          </View>

          {/* AVATAR */}
          <View style={styles.profileRow}>
            <View style={styles.avatarWrapper}>
              {avatar ? (
                <Image source={{ uri: avatar }} style={styles.avatar} />
              ) : (
                <FallbackAvatar size={80} />
              )}
            </View>
          </View>

          {/* PROFILE DETAILS */}
          <View style={styles.details}>
            {!!name && <Text style={styles.name}>{name}</Text>}
            {!!website && <Text style={styles.website}>{website}</Text>}
            {!!bio && <Text style={styles.bio}>{bio}</Text>}

            {!!location && (
              <View style={styles.locationRow}>
                <Ionicons
                  name="location-outline"
                  size={14}
                  color="#666"
                />
                <Text style={styles.location}>{location}</Text>
              </View>
            )}

            <TouchableOpacity
              style={styles.editBtn}
              onPress={() => router.push("/profile/edit")}
            >
              <Ionicons name="pencil-outline" size={14} color="#000" />
              <Text style={styles.editText}>Edit Profile</Text>
            </TouchableOpacity>

            <View style={styles.statsRow}>
  <StatItem label="Posts" value={posts.length} />
  <ProfileStats
    uid={profileUid!}
    followers={followersCount ?? 0}
    following={followingCount ?? 0}
  />
</View>
          </View>

          {/* SECTION TABS */}
          <View style={styles.sectionTabs}>
            <SectionTab icon="grid-outline" label="Posts" active />
            <SectionTab
              icon="heart-outline"
              label="Wellness"
              onPress={() => router.push("/(tabs)/profile/wellness")}
            />
            <SectionTab
              icon="game-controller-outline"
              label="Games"
              onPress={() => router.push("/(tabs)/profile/games")}
            />
            <SectionTab
              icon="bookmark-outline"
              label="Saved"
              onPress={() => router.push("/(tabs)/profile/saved")}
            />
          </View>

          {/* FILTERS */}
          <View style={styles.filters}>
            {[
              { key: "all", label: "All" },
              { key: "text", label: "Texts" },
              { key: "photo", label: "Photos" },
              { key: "video", label: "Videos" },
              { key: "repost", label: "Reposts" },
            ].map((item) => (
              <TouchableOpacity
                key={item.key}
                style={[
                  styles.filterChip,
                  activeFilter === item.key &&
                    styles.filterActive,
                ]}
                onPress={() =>
                  setActiveFilter(item.key as FilterType)
                }
              >
                <Text
                  style={[
                    styles.filterText,
                    activeFilter === item.key &&
                      styles.filterTextActive,
                  ]}
                >
                  {item.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </>
      }
    />
  </View>
);
}

/* ---------------- SMALL COMPONENTS ---------------- */

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.statItem}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function SectionTab({
  icon,
  label,
  active,
  onPress,
}: {
  icon: any;
  label: string;
  active?: boolean;
  onPress?: () => void;
}) {
  return (
    <TouchableOpacity
      onPress={onPress}
      style={styles.sectionTab}
      activeOpacity={0.7}
    >
      <Ionicons
        name={icon}
        size={20}
        color={active ? "#000" : "#aaa"}
      />
      <Text
        style={[
          styles.sectionText,
          active && { color: "#000" },
        ]}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );
}

function StatItem({
  label,
  value,
}: {
  label: string;
  value: number;
}) {
  return (
    <View style={styles.statItem}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#fff" },

  cover: { height: 140, backgroundColor: "#eee" },

  profileRow: { marginTop: -40, paddingLeft: 16 },
  avatarWrapper: { width: 80, height: 80 },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 3,
    borderColor: "#fff",
  },

  details: { paddingHorizontal: 16, marginTop: 12 },
  name: { fontSize: 18, fontWeight: "700" },
  website: { color: "#1a73e8", marginTop: 4 },
  bio: { marginTop: 6, color: "#444" },

  locationRow: {
    flexDirection: "row",
    alignItems: "center",
    marginTop: 6,
  },
  statsRow: {
  flexDirection: "row",
  justifyContent: "space-around",
  paddingVertical: 14,
  borderTopWidth: 1,
  borderBottomWidth: 1,
  borderColor: "#eee",
  marginTop: 12,
},

  location: { marginLeft: 4, color: "#666", fontSize: 13 },

  editBtn: {
    marginTop: 14,
    flexDirection: "row",
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#ddd",
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 20,
    alignSelf: "flex-start",
  },
  editText: {
    marginLeft: 6,
    fontSize: 13,
    fontWeight: "500",
  },

  stats: {
    flexDirection: "row",
    justifyContent: "space-around",
    paddingVertical: 12,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: "#eee",
  },
  statItem: { alignItems: "center", flex: 1,
  },
  statValue: { fontSize: 16, fontWeight: "700" },
  statLabel: { fontSize: 12, color: "#666", marginTop: 2,},

  sectionTabs: {
    flexDirection: "row",
    justifyContent: "space-around",
    paddingVertical: 12,
  },
  sectionTab: { alignItems: "center" },
  sectionText: {
    fontSize: 12,
    color: "#aaa",
    marginTop: 4,
  },

  filters: {
    flexDirection: "row",
    paddingHorizontal: 12,
    marginBottom: 8,
  },
  filterChip: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 16,
    marginRight: 8,
    backgroundColor: "#f2f2f2",
  },
  filterActive: { backgroundColor: "#000" },
  filterText: { fontSize: 12, color: "#666" },
  filterTextActive: { color: "#fff" },
});
