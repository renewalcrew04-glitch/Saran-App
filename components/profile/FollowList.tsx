import {
  View,
  FlatList,
  TextInput,
  StyleSheet,
} from "react-native";
import { useEffect, useState } from "react";
import { useDebounce } from "@/hooks/useDebounce";
import ProfileRow from "@/components/profile/ProfileRow";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/services/firebase";
import SkeletonRow from "@/components/ui/SkeletonRow";

type Result = {
  uid: string;
  name?: string;
  avatar?: string;
};

export default function FollowList({
  uid,
  fetcher,
}: {
  uid: string;
  fetcher: (
    uid: string,
    search?: string,
    lastDoc?: any
  ) => Promise<{
    data: Result[];
    lastDoc: any;
  }>;
}) {
  const [items, setItems] = useState<Result[]>([]);
  const [lastDoc, setLastDoc] = useState<any>(null);
  const [search, setSearch] = useState("");
  const debounced = useDebounce(search, 400);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    load(true);
  }, [debounced, uid]);

  async function load(reset = false) {
    if (loading) return;
    setLoading(true);

    const res = await fetcher(
      uid,
      debounced,
      reset ? null : lastDoc
    );

    const enriched = await Promise.all(
      res.data.map(async (item) => {
        const snap = await getDoc(
          doc(db, "profiles", item.uid)
        );

        if (!snap.exists()) {
          return {
            uid: item.uid,
            name: "Unknown",
            avatar: undefined,
          };
        }

        const data = snap.data();

        return {
          uid: item.uid,
          name: data.name ?? "Unknown",
          avatar: data.avatar,
        };
      })
    );

    setItems((prev) => {
      const merged = reset
        ? enriched
        : [...prev, ...enriched];

      return Array.from(
        new Map(merged.map((u) => [u.uid, u])).values()
      );
    });

    setLastDoc(res.lastDoc);
    setLoading(false);
  }

  return (
  <View style={{ flex: 1 }}>
    <TextInput
      placeholder="Search"
      value={search}
      onChangeText={setSearch}
      style={styles.search}
    />

    {loading && items.length === 0 ? (
  <View>
    {Array.from({ length: 6 }).map((_, i) => (
      <SkeletonRow key={`sk-${i}`} />
    ))}
  </View>
) : (
  <FlatList
    data={items}
    keyExtractor={(i) => `follow-${i.uid}`}
    renderItem={({ item }) => (
      <ProfileRow uid={item.uid} showFollow />
    )}
    onEndReached={() => load()}
    onEndReachedThreshold={0.4}
  />
)}
  </View>
);}

const styles = StyleSheet.create({
  search: {
    padding: 12,
    borderBottomWidth: 1,
    borderColor: "#eee",
  },
});
