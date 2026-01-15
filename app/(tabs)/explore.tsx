import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
} from "react-native";
import { Platform, StatusBar } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useEffect, useState } from "react";
import { Ionicons } from "@expo/vector-icons";
import Screen from "@/components/Screen";
import ProfilePostGrid from "@/components/profile/ProfilePostGrid";
import PeopleList from "@/components/explore/PeopleList";
import { useDebounce } from "@/hooks/useDebounce";
import {
  fetchExplorePostsPaginated,
  fetchExplorePeople,
} from "@/services/explore";
import {
  searchPeople,
  searchPostsPaginated,
} from "@/services/search";
import type { QueryDocumentSnapshot } from "firebase/firestore";

type Tab = "all" | "people" | "text" | "photo" | "video";

export default function Explore() {
  const router = useRouter();
  const params = useLocalSearchParams<{ tab?: Tab }>();

  const [tab, setTab] = useState<Tab>("all");
  const [posts, setPosts] = useState<any[]>([]);
  const [people, setPeople] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [queryText, setQueryText] = useState("");
  const debouncedQuery = useDebounce(queryText, 400);
  const [cursor, setCursor] =
    useState<QueryDocumentSnapshot | undefined>();
  const [hasMore, setHasMore] = useState(true);

  /* 🔹 Handle ?tab=people from View more */
  useEffect(() => {
    if (params.tab === "people") {
      setTab("people");
    }
  }, [params.tab]);

  useEffect(() => {
    resetAndLoad();
  }, [tab, debouncedQuery]);

  async function resetAndLoad() {
    setPosts([]);
    setPeople([]);
    setCursor(undefined);
    setHasMore(true);
    await loadFirstPage();
  }

  async function loadFirstPage() {
    setLoading(true);

    /* 🔍 SEARCH MODE */
    if (debouncedQuery.trim()) {
      if (tab === "people") {
        const res = await searchPeople(debouncedQuery);
        setPeople(res.slice(0, 50));
      } else if (tab === "all") {
        const [ppl, pst] = await Promise.all([
          searchPeople(debouncedQuery),
          searchPostsPaginated({ text: debouncedQuery }),
        ]);
        setPeople(ppl.slice(0, 3));
        setPosts(pst.posts);
        setCursor(pst.cursor);
        setHasMore(!!pst.cursor);
      } else {
        const pst = await searchPostsPaginated({
          text: debouncedQuery,
          type: tab,
        });
        setPosts(pst.posts);
        setCursor(pst.cursor);
        setHasMore(!!pst.cursor);
      }
    }

    /* 🔹 NORMAL MODE */
    else {
      if (tab === "people") {
        const res = await fetchExplorePeople(50);
        setPeople(res);
      } else if (tab === "all") {
        const [ppl, pst] = await Promise.all([
          fetchExplorePeople(3),
          fetchExplorePostsPaginated({}),
        ]);
        setPeople(ppl);
        setPosts(pst.posts);
        setCursor(pst.cursor);
        setHasMore(!!pst.cursor);
      } else {
        const pst = await fetchExplorePostsPaginated({
          type: tab,
        });
        setPosts(pst.posts);
        setCursor(pst.cursor);
        setHasMore(!!pst.cursor);
      }
    }

    setLoading(false);
  }

  async function loadMore() {
    if (!hasMore || loadingMore || loading || tab === "people") return;

    setLoadingMore(true);

    const res = debouncedQuery.trim()
      ? await searchPostsPaginated({
          text: debouncedQuery,
          cursor,
          type: tab === "all" ? undefined : tab,
        })
      : await fetchExplorePostsPaginated({
          cursor,
          type: tab === "all" ? undefined : tab,
        });

    setPosts((p) => [...p, ...res.posts]);
    setCursor(res.cursor);
    setHasMore(!!res.cursor);
    setLoadingMore(false);
  }

  return (
    <Screen>
      {/* SEARCH */}
      <View style={styles.searchWrapper}>
  <LinearGradient
    colors={["#0b0b0b", "#1c1c1c", "#0b0b0b"]}
    start={{ x: 0, y: 0 }}
    end={{ x: 1, y: 1 }}
    style={styles.searchGradient}
  >
    {/* Gloss overlay */}
    <View style={styles.searchGloss} />

    <Ionicons
  name="search-outline"
  size={16}
  color="#bbb"
  style={{ marginRight: 8 }}
/>

    <TextInput
      placeholder="Search"
      placeholderTextColor="#aaa"
      value={queryText}
      onChangeText={setQueryText}
      style={styles.searchInput}
    />
  </LinearGradient>
</View>
<View style={{ height: 8 }} />
      {/* TABS */}
      <View style={styles.tabs}>
        {TABS.map((t) => (
          <TouchableOpacity
            key={t.key}
            onPress={() => setTab(t.key)}
            style={[
              styles.tab,
              tab === t.key && styles.tabActive,
            ]}
          >
            <Ionicons
              name={t.icon}
              size={16}
              color={tab === t.key ? "#000" : "#999"}
            />
            <Text
              style={[
                styles.tabText,
                tab === t.key && styles.tabTextActive,
              ]}
            >
              {t.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* CONTENT */}
      {tab === "people" ? (
        <PeopleList people={people} loading={loading} />
      ) : (
        <>
          {tab === "all" && people.length > 0 && (
  <>
    <Text style={styles.suggestionLabel}>
      Suggestions for you
    </Text>

    <PeopleList people={people} />

              <TouchableOpacity
                onPress={() => router.push("/explore?tab=people")}
                style={{ paddingTop: 1, paddingBottom: 6 }}
              >
                <Text
                  style={{
                    textAlign: "center",
                    color: "#666",
                    fontSize: 13,
                  }}
                >
                  View more
                </Text>
              </TouchableOpacity>
            </>
          )}

          <ProfilePostGrid
            posts={posts}
            aspectRatio={tab === "video" ? 9 / 16 : undefined}
            textOnly={tab === "text"}
            onEndReached={loadMore}
          />
        </>
      )}
    </Screen>
  );
}

/* ---------------- CONSTANTS ---------------- */

const TABS: {
  key: Tab;
  label: string;
  icon:
    | "grid-outline"
    | "people-outline"
    | "document-text-outline"
    | "image-outline"
    | "play-outline";
}[] = [
  { key: "all", label: "All", icon: "grid-outline" },
  { key: "people", label: "People", icon: "people-outline" },
  { key: "text", label: "Texts", icon: "document-text-outline" },
  { key: "photo", label: "Photos", icon: "image-outline" },
  { key: "video", label: "Videos", icon: "play-outline" },
];

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  search: {
  flexDirection: "row",
  padding: 12,
  borderRadius: 10,
  backgroundColor: "#f2f2f2",
  margin: 12,
},
  searchWrapper: {
  marginHorizontal: 16,
  marginBottom: 10,
  marginTop:
    Platform.OS === "android"
      ? (StatusBar.currentHeight ?? 0) + 1
      : 12,
},
suggestionLabel: {
  marginHorizontal: 16,
  marginBottom: 6,
  fontSize: 13,
  fontWeight: "600",
  color: "#555",
},
searchGradient: {
  flexDirection: "row",
  alignItems: "center",
  height: 40,
  paddingHorizontal: 14,
  borderRadius: 20,
  width: "100%",
  overflow: "hidden",
  minHeight: 42,
},

searchGloss: {
  position: "absolute",
  top: 0,
  left: 0,
  right: 0,
  height: "38%",
  backgroundColor: "rgba(255,255,255,0.08)",
},

searchInput: {
  flex: 1,
  fontSize: 13,
  color: "#fff",
  padding: 0,
},
  tabs: {
  flexDirection: "row",
  paddingHorizontal: 12,
  marginBottom: 10, // 👈 space before people
},
  tab: {
  flexDirection: "row",
  alignItems: "center",
  paddingHorizontal: 12,
  paddingVertical: 6,
  borderRadius: 16,
  backgroundColor: "#f2f2f2",
  marginRight: 8,
},
  tabActive: {
    backgroundColor: "#fff",
    borderWidth: 1,
    borderColor: "#000",
  },
  tabText: { fontSize: 12, color: "#999" },
  tabTextActive: { color: "#000", fontWeight: "600" },
});
