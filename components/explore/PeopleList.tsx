import { View, StyleSheet } from "react-native";
import { getAuth } from "firebase/auth";
import PeopleRow from "./PeopleRow";
import SkeletonRow from "@/components/ui/SkeletonRow";

export default function PeopleList({
  people,
  loading = false,
}: {
  people: any[];
  loading?: boolean;
}) {
  const currentUid = getAuth().currentUser?.uid;
  if (!currentUid) return null;

  if (loading) {
    return (
      <View style={styles.list}>
        {Array.from({ length: 5 }).map((_, i) => (
          <SkeletonRow key={`sk-${i}`} />
        ))}
      </View>
    );
  }

  return (
    <View style={styles.list}>
      {people
        .filter((p) => p.uid !== currentUid)
        .map((p) => (
          <PeopleRow key={`p-${p.uid}`} person={p} />
        ))}
    </View>
  );
}

const styles = StyleSheet.create({
  list: {
    paddingHorizontal: 16,
    paddingTop: 4,
    paddingBottom: 2,
  },
});
