import { View } from "react-native";
import { FontAwesomeIcon } from "@fortawesome/react-native-fontawesome";
import { faUserTie } from "@fortawesome/free-solid-svg-icons";

type Props = {
  size?: number;
  color?: string;
};

export default function FallbackAvatar({
  size = 48,
  color = "#666",
}: Props) {
  return (
    <View
      style={{
        width: size,
        height: size,
        borderRadius: size / 2,
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: "#111",
      }}
    >
      <FontAwesomeIcon
        icon={faUserTie}
        size={size * 0.55}
        color={color}
      />
    </View>
  );
}
