import { View } from "react-native";
import { FontAwesome5 } from "@expo/vector-icons";

export function Plant({ stage }: { stage: number }) {
  const icon =
    stage === 0
      ? "dot-circle"
      : stage === 1
      ? "seedling"
      : "tree";

  return (
    <View
      style={{
        flex: 1,
        borderRadius: 16,
        backgroundColor: "#f5f5f5",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <FontAwesome5 name={icon} size={26} />
    </View>
  );
}
