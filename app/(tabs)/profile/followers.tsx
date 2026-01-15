import Screen from "@/components/Screen";
import FollowList from "@/components/profile/FollowList";
import { fetchFollowersPaginated } from "@/services/followLists";
import { useLocalSearchParams } from "expo-router";

export default function Followers() {
  const { uid } = useLocalSearchParams<{ uid: string }>();
  if (!uid) return null;

  return (
    <Screen>
      <FollowList
        uid={uid}
        fetcher={fetchFollowersPaginated}
      />
    </Screen>
  );
}
