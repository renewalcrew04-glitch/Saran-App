import Screen from "@components/Screen";
import AppHeader from "@components/AppHeader";
import HomeFeed from "@components/HomeFeed";
import { useEffect } from "react";
import { useRouter } from "expo-router";
import { useProfileStore } from "@/store/profileStore";

export default function Home() {
  const router = useRouter();
  const { verificationStep } = useProfileStore();

  useEffect(() => {
    if (verificationStep !== "verified") {
      router.replace("/verification/pending");
    }
  }, [verificationStep]);

  return (
    <Screen>
      <AppHeader />
      <HomeFeed />
    </Screen>
  );
}
