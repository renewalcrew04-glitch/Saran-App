import { collection, getDocs, limit, query } from "firebase/firestore";
import { db, auth } from "@/services/firebase";
import { getMyFollowData } from "./followLists";
//import { getSavedContacts } from "./contacts";

async function getFriendsOfFriends(
  myUid: string,
  followingIds: Set<string>
): Promise<Set<string>> {
  const fof = new Set<string>();

  for (const uid of followingIds) {
    const snap = await getDocs(
      collection(db, "follows", uid, "following")
    );

    snap.docs.forEach(d => {
      if (d.id !== myUid && !followingIds.has(d.id)) {
        fof.add(d.id);
      }
    });
  }

  return fof;
}

export type Person = {
  uid: string;
  name: string;
  avatar?: string;
  phone?: string;
};

export async function fetchPeople(
  currentUid?: string,
  max = 10
): Promise<Person[]> {
  if (!auth.currentUser || !currentUid) return [];

  // 1. Get follow data
  const { followingIds, followerIds } = await getMyFollowData(currentUid);

  const friendsOfFriends = await getFriendsOfFriends(
  currentUid,
  followingIds
);

const contactPhones = new Set<string>();

  // 2. Fetch users
  const q = query(collection(db, "profiles"), limit(200));
  const snap = await getDocs(q);

  const users: Person[] = snap.docs.map((d) => ({
  uid: d.id,
  name: d.data().name || "User",
  avatar: d.data().avatar || "",
  phone: d.data().phone || "",
}));

  // 3. Remove self + already-followed
  const filtered = users.filter((u) => {
    if (u.uid === currentUid) return false;
    if (followingIds.has(u.uid)) return false;
    return true;
  });

  // 4. Follow-back first
  const followBack = filtered.filter(u =>
    followerIds.has(u.uid)
  );

  const followBackIds = new Set(followBack.map(u => u.uid));

  // Users who are NOT follow-back
const others: Person[] = filtered.filter(
  (u: Person) => !followerIds.has(u.uid)
);

  // 5. Friends of Friends
const fofUsers: Person[] = others.filter(
  (u: Person) =>
    !followBackIds.has(u.uid) &&
    friendsOfFriends.has(u.uid)
);

// 6. Contacts (exclude fof to avoid duplicates)
const contactUsers: Person[] = others.filter(
  (u: Person) =>
    !followBackIds.has(u.uid) &&
    !friendsOfFriends.has(u.uid) &&
    u.phone &&
    contactPhones.has(u.phone)
);

// 7. Remaining users
const remaining: Person[] = others.filter(
  (u: Person) =>
    !followBackIds.has(u.uid) &&
    !friendsOfFriends.has(u.uid) &&
    (!u.phone || !contactPhones.has(u.phone))
);

// 8. Final ranked order (SOURCE OF TRUTH)
const ranked = [
  ...followBack.map(u => ({
    ...u,
    followsYou: true,
    mutualCount: 0,
  })),

  ...fofUsers.map(u => ({
    ...u,
    followsYou: false,
    mutualCount: 1, // FoF presence (can be expanded later)
  })),

  ...contactUsers.map(u => ({
    ...u,
    followsYou: false,
    mutualCount: 0,
  })),

  ...remaining.map(u => ({
    ...u,
    followsYou: false,
    mutualCount: 0,
  })),
];

// 9. Hard cap
return ranked.slice(0, max);
}