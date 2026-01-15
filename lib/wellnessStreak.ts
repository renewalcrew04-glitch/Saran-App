import AsyncStorage from "@react-native-async-storage/async-storage";

const STREAK_KEY = "WELLNESS_STREAK";

type StreakData = {
  lastCompleted: string; // yyyy-mm-dd
  current: number;
  longest: number;
};

const todayString = () =>
  new Date().toISOString().split("T")[0];

export async function markWellnessCompleted() {
  const today = todayString();

  const raw = await AsyncStorage.getItem(STREAK_KEY);
  let data: StreakData | null = raw ? JSON.parse(raw) : null;

  if (!data) {
    const newData: StreakData = {
      lastCompleted: today,
      current: 1,
      longest: 1,
    };
    await AsyncStorage.setItem(STREAK_KEY, JSON.stringify(newData));
    return newData;
  }

  if (data.lastCompleted === today) {
    // already counted today
    return data;
  }

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().split("T")[0];

  let current = 1;

  if (data.lastCompleted === yesterdayStr) {
    current = data.current + 1;
  }

  const updated: StreakData = {
    lastCompleted: today,
    current,
    longest: Math.max(data.longest, current),
  };

  await AsyncStorage.setItem(STREAK_KEY, JSON.stringify(updated));
  return updated;
}

export async function getWellnessStreak(): Promise<StreakData | null> {
  const raw = await AsyncStorage.getItem(STREAK_KEY);
  return raw ? JSON.parse(raw) : null;
}
