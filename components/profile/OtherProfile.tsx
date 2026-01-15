import {
  View,
  Text,
  Image,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { auth, db } from "@/services/firebase";
import { useEffect, useState, useCallback } from "react";
import { doc, getDoc } from "firebase/firestore";
import { useRouter } from "expo-router";

import FallbackAvatar from "@/components/ui/FallbackAvatar";
import CoverPlaceholder from "@/components/ui/CoverPlaceholder";
import ProfilePostGrid from "@/components/profile/ProfilePostGrid";
import ProfileMenu from "@/components/profile/ProfileMenu";

import { fetchUserPosts } from "@/services/posts";
import type { Post } from "@/services/posts";
import { followUser, unfollowUser } from "@/utils/follow";
import { useFollowStatus } from "@/utils/useFollowStatus";
import {
  getFollowersCount,
  getFollowingCount,
} from "@/services/followCounts";
import { getOrCreateConversation } from "@/services/dm";

/* ---------------- TYPES ---------------- */

type Profile = {
  name?: string;
  bio?: string;
  website?: string;
  location?: string;
  avatar?: string;
  cover?: string;
};

/* ---------------- HEADER ---------------- */

function ProfileHeader({
  profile,
  posts,
  followers,
  following,
  uid,
  router,
  isFollowing,
  toggleFollow,
  activeFilter,
  setActiveFilter,
  menuVisible,
  setMenuVisible,
}: any) {
  return (
    <>
      {/* COVER */}
      <View style={styles.cover}>
        {profile.cover ? (
          <Image source={{ uri: profile.cover }} style={styles.cover} />
        ) : (
          <CoverPlaceholder height={160} />
        )}

        <TouchableOpacity
          style={styles.menuBtn}
          onPress={() => setMenuVisible(true)}
        >
          <Ionicons name="ellipsis-vertical" size={22} />
        </TouchableOpacity>
      </View>

      {menuVisible && (
        <ProfileMenu uid={uid} onClose={() => setMenuVisible(false)} />
      )}

      {/* AVATAR */}
      <View style={styles.avatarWrap}>
        {profile.avatar ? (
          <Image source={{ uri: profile.avatar }} style={styles.avatar} />
        ) : (
          <FallbackAvatar size={64} />
        )}
      </View>

      {/* INFO */}
      <View style={styles.info}>
        {!!profile.name && <Text style={styles.name}>{profile.name}</Text>}
        {!!profile.website && (
          <Text style={styles.website}>{profile.website}</Text>
        )}
        {!!profile.bio && <Text style={styles.bio}>{profile.bio}</Text>}
        {!!profile.location && (
          <View style={styles.locationRow}>
            <Ionicons name="location-outline" size={14} color="#666" />
            <Text style={styles.location}>{profile.location}</Text>
          </View>
        )}
      </View>

      {/* STATS */}
      <View style={styles.stats}>
        <View style={{ alignItems: "center" }}>
          <Text style={styles.statValue}>{posts.length}</Text>
          <Text style={styles.statLabel}>Posts</Text>
        </View>

        <TouchableOpacity
          style={{ alignItems: "center" }}
          onPress={() =>
            router.push(`/profile/followers?uid=${uid}`)
          }
        >
          <Text style={styles.statValue}>{followers}</Text>
          <Text style={styles.statLabel}>Followers</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={{ alignItems: "center" }}
          onPress={() =>
            router.push(`/profile/following?uid=${uid}`)
          }
        >
          <Text style={styles.statValue}>{following}</Text>
          <Text style={styles.statLabel}>Following</Text>
        </TouchableOpacity>
      </View>

      {/* ACTIONS */}
      <View style={styles.actions}>
        <TouchableOpacity
          style={[
            styles.followBtn,
            isFollowing && styles.followingBtn,
          ]}
          onPress={toggleFollow}
        >
          <Text style={styles.followText}>
            {isFollowing ? "Following" : "Follow"}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.dmBtn}
          onPress={async () => {
            const currentUid = auth.currentUser?.uid;
            if (!currentUid) return;
            const cid = await getOrCreateConversation(
              currentUid,
              uid
            );
            router.push(`/messages/chat?cid=${cid}`);
          }}
        >
          <Ionicons name="chatbubble-outline" size={18} />
        </TouchableOpacity>
      </View>

      {/* FILTERS */}
      <View style={styles.filters}>
        {["all", "text", "photo", "video", "repost"].map((k) => (
          <TouchableOpacity
            key={k}
            style={[
              styles.filterChip,
              activeFilter === k && styles.filterActive,
            ]}
            onPress={() => setActiveFilter(k as any)}
          >
            <Text
              style={[
                styles.filterText,
                activeFilter === k && styles.filterTextActive,
              ]}
            >
              {k.toUpperCase()}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </>
  );
}

/* ---------------- MAIN ---------------- */

export default function OtherProfile({ uid }: { uid: string }) {
  const router = useRouter();
  const { isFollowing, loading: followLoading } =
    useFollowStatus(uid);

  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [followers, setFollowers] = useState(0);
  const [following, setFollowing] = useState(0);
  const [updating, setUpdating] = useState(false);
  const [menuVisible, setMenuVisible] = useState(false);

  const [posts, setPosts] = useState<Post[]>([]);
  const [activeFilter, setActiveFilter] =
    useState<"all" | "text" | "photo" | "video" | "repost">(
      "all"
    );

  /* LOAD COUNTS */
  const loadCounts = useCallback(async () => {
    setFollowers(await getFollowersCount(uid));
    setFollowing(await getFollowingCount(uid));
  }, [uid]);

  /* LOAD PROFILE */
  useEffect(() => {
    const load = async () => {
      const snap = await getDoc(doc(db, "profiles", uid));
      if (snap.exists()) {
        setProfile(snap.data() as Profile);
      }
      await loadCounts();
      setLoading(false);
    };
    load();
  }, [uid, loadCounts]);

  /* LOAD POSTS */
  useEffect(() => {
    fetchUserPosts(uid).then(setPosts);
  }, [uid]);

  const filteredPosts =
    activeFilter === "all"
      ? posts
      : posts.filter((p) => p.type === activeFilter);

  /* FOLLOW */
  const toggleFollow = async () => {
    if (followLoading || updating) return;
    setUpdating(true);

    try {
      const currentUid = auth.currentUser?.uid;
      if (!currentUid) return;

      if (isFollowing) {
        await unfollowUser(currentUid, uid);
        setFollowers((v) => Math.max(0, v - 1));
      } else {
        await followUser(currentUid, uid);
        setFollowers((v) => v + 1);
      }
    } finally {
      setUpdating(false);
    }
  };

  if (loading || !profile) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return (
    <ProfilePostGrid
      posts={filteredPosts}
      ListHeaderComponent={
        <ProfileHeader
          profile={profile}
          posts={posts}
          followers={followers}
          following={following}
          uid={uid}
          router={router}
          isFollowing={isFollowing}
          toggleFollow={toggleFollow}
          activeFilter={activeFilter}
          setActiveFilter={setActiveFilter}
          menuVisible={menuVisible}
          setMenuVisible={setMenuVisible}
        />
      }
    />
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  center: { flex: 1, justifyContent: "center", alignItems: "center" },

  cover: { height: 160, backgroundColor: "#eee" },
  menuBtn: {
    position: "absolute",
    right: 12,
    top: 12,
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 6,
  },

  avatarWrap: { marginTop: -40, paddingLeft: 16 },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 3,
    borderColor: "#fff",
  },

  info: { paddingHorizontal: 16, marginTop: 12 },
  name: { fontSize: 18, fontWeight: "700" },
  website: { color: "#1a73e8", marginTop: 4 },
  bio: { marginTop: 6, color: "#444" },

  locationRow: {
    flexDirection: "row",
    alignItems: "center",
    marginTop: 6,
  },
  location: { marginLeft: 4, color: "#666", fontSize: 13 },

  stats: {
    flexDirection: "row",
    justifyContent: "space-around",
    paddingVertical: 14,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: "#eee",
    marginTop: 16,
  },
  statValue: { fontSize: 16, fontWeight: "700" },
  statLabel: { fontSize: 12, color: "#666" },

  filters: { flexDirection: "row", padding: 12 },
  filterChip: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 16,
    backgroundColor: "#eee",
    marginRight: 8,
  },
  filterActive: { backgroundColor: "#000" },
  filterText: { fontSize: 12, color: "#666" },
  filterTextActive: { color: "#fff" },

  actions: { flexDirection: "row", gap: 12, padding: 16 },
  followBtn: {
    flex: 1,
    backgroundColor: "#000",
    paddingVertical: 12,
    borderRadius: 24,
    alignItems: "center",
  },
  followingBtn: { backgroundColor: "#333" },
  followText: { color: "#fff", fontWeight: "600" },

  dmBtn: {
    width: 48,
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 24,
    alignItems: "center",
    justifyContent: "center",
  },
});
