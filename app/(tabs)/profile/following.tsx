import Screen from "@/components/Screen";
import FollowList from "@/components/profile/FollowList";
import { fetchFollowingPaginated } from "@/services/followLists";
import { useLocalSearchParams } from "expo-router";

export default function Following() {
  const { uid } = useLocalSearchParams<{ uid: string }>();
  if (!uid) return null;

  return (
    <Screen>
      <FollowList
        uid={uid}
        fetcher={fetchFollowingPaginated}
      />
    </Screen>
  );
}
