import { View, FlatList } from "react-native";

type GridItem = {
  id: string;
  type: "image" | "video";
};

type Props = {
  type: "posts" | "videos";
  limit?: number;
};

export default function MediaGrid({ type, limit }: Props) {
  // TEMP MOCK DATA
  const data: GridItem[] = [
    { id: "1", type: "image" },
    { id: "2", type: "video" },
    { id: "3", type: "image" },
    { id: "4", type: "video" },
    { id: "5", type: "image" },
    { id: "6", type: "video" },
  ];

  const filtered =
    type === "videos"
      ? data.filter((i) => i.type === "video")
      : data;

  const finalData = limit ? filtered.slice(0, limit) : filtered;

  return (
    <FlatList
      data={finalData}
      numColumns={3}
      keyExtractor={(item) => item.id}
      renderItem={() => (
        <View
          style={{
            width: "33.33%",
            aspectRatio: 1,
            backgroundColor: "#eee",
            borderWidth: 0.5,
          }}
        />
      )}
    />
  );
}
