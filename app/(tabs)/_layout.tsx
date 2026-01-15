import { Tabs, Redirect } from "expo-router";
import { FontAwesome6 } from "@expo/vector-icons";
import { View, Text, StyleSheet } from "react-native";
import { Colors } from "@constants/colors";
import { useProfileStore } from "@/store/profileStore";

const tabBarIcon =
  (name: any) =>
  ({ focused }: { focused: boolean }) =>
    (
      <FontAwesome6
        name={name}
        solid={focused}
        size={20}
        color={Colors.black}
      />
    );

const tabsScreenOptions = {
  headerShown: false,
  tabBarShowLabel: false,
  tabBarStyle: {
    height: 68,
    borderTopColor: Colors.gray200,
    backgroundColor: Colors.white,
  },
};

export default function TabsLayout() {
  const {
    profileCompleted,
    verified,
    _hydratedUid,
  } = useProfileStore();

  // ⏳ WAIT until profile is hydrated
  if (!_hydratedUid) {
    return null;
  }

  // 🔒 MUST complete profile
  if (!profileCompleted) {
    return <Redirect href="/profile/complete" />;
  }

  // 🔒 MUST be admin verified
  if (!verified) {
    return <Redirect href="/verification/pending" />;
  }

  // ✅ ONLY VERIFIED USERS CAN SEE TABS
  return (
    <Tabs screenOptions={tabsScreenOptions}>
      <Tabs.Screen
        name="home"
        options={{ tabBarIcon: tabBarIcon("house") }}
      />

      <Tabs.Screen
        name="explore"
        options={{ tabBarIcon: tabBarIcon("compass") }}
      />

      <Tabs.Screen
        name="sos"
        options={{
          tabBarIcon: () => (
            <View style={styles.sos}>
              <Text style={styles.sosText}>SOS</Text>
            </View>
          ),
        }}
      />

      <Tabs.Screen
        name="space"
        options={{ tabBarIcon: tabBarIcon("calendar-days") }}
      />

      <Tabs.Screen
        name="profile"
        options={{ tabBarIcon: tabBarIcon("user") }}
      />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  sos: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: Colors.red,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 24,
  },
  sosText: {
    color: Colors.white,
    fontWeight: "700",
    fontSize: 12,
    letterSpacing: 1,
  },
});
