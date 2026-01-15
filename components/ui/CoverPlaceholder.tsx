import { View } from "react-native";
import { FontAwesomeIcon } from "@fortawesome/react-native-fontawesome";
import { faCamera } from "@fortawesome/free-solid-svg-icons";

export default function CoverPlaceholder({
  height = 140,
}: {
  height?: number;
}) {
  return (
    <View
      style={{
        height,
        width: "100%",
        backgroundColor: "#111",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <FontAwesomeIcon
        icon={faCamera}
        size={42}
        color="#444"
      />
    </View>
  );
}
