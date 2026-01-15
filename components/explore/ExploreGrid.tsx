import { ExploreTabType } from "./types";
import MediaGrid from "./MediaGrid";

type Props = {
  activeTab: ExploreTabType;
};

export default function ExploreGrid({ activeTab }: Props) {
  if (activeTab === "posts") {
    return <MediaGrid type="posts" />;
  }

  if (activeTab === "videos") {
    return <MediaGrid type="videos" />;
  }

  if (activeTab === "all") {
    return <MediaGrid type="posts" />;
  }

  return null;
}
