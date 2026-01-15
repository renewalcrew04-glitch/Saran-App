import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";


/* -------------------- TYPES -------------------- */
type CardProps = {
  title: string;
  desc: string;
  onPress: () => void;
};

type HeaderProps = {
  title: string;
};

/* -------------------- SCREEN -------------------- */
export default function CalmCorner() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Header title="Calm Corner" />

      <Card
        title="1-Minute Breathing"
        desc="Calm your mind"
        onPress={() => router.push("/wellness/breathing")}
      />

      <Card
        title="5-4-3-2-1 Grounding"
        desc="Return to the present"
        onPress={() => router.push("/wellness/grounding")}
      />

      <Card
        title="Eye Relaxation"
        desc="Rest your eyes"
        onPress={() => router.push("/wellness/eye-relax")}
      />
    </View>
  );
}

/* -------------------- CARD -------------------- */
function Card({ title, desc, onPress }: CardProps) {
  const handlePress = async () => {
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onPress();
  };

  return (
    <TouchableOpacity onPress={handlePress} style={styles.card}>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.cardDesc}>{desc}</Text>
    </TouchableOpacity>
  );
}


/* -------------------- HEADER -------------------- */
function Header({ title }: HeaderProps) {
  const router = useRouter();

  return (
    <TouchableOpacity onPress={() => router.back()}>
      <Text style={styles.back}>← {title}</Text>
    </TouchableOpacity>
  );
}

/* -------------------- STYLES -------------------- */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#fff",
  },
  back: {
    fontSize: 16,
    marginBottom: 20,
  },
  card: {
    padding: 18,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#eee",
    marginBottom: 12,
  },
  cardTitle: {
    fontSize: 15,
    fontWeight: "600",
  },
  cardDesc: {
    fontSize: 12,
    color: "#666",
    marginTop: 4,
  },
});
