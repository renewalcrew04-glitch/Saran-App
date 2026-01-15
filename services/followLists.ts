import {
  collection,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  where,
  QueryDocumentSnapshot,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";

/* ---------- INTERNAL HELPER ---------- */

async function fetchPaginated(
  collectionRef: ReturnType<typeof collection>,
  search?: string,
  lastDoc?: QueryDocumentSnapshot
) {
  // 🔒 AUTH GATE (FIRST LINE)
  if (!auth.currentUser) {
    return { data: [], lastDoc: null };
  }

  let q = query(
    collectionRef,
    orderBy("createdAt", "desc"),
    limit(20)
  );

  if (search) {
    q = query(
      collectionRef,
      orderBy("name"),
      where("name", ">=", search),
      where("name", "<=", search + "\uf8ff"),
      limit(20)
    );
  }

  if (lastDoc) {
    q = query(q, startAfter(lastDoc));
  }

  const snap = await getDocs(q);

  return {
    data: snap.docs.map((d) => ({
      uid: d.id,
      ...d.data(),
    })),
    lastDoc: snap.docs[snap.docs.length - 1] || null,
  };
}

/* ---------- FOLLOWERS ---------- */

export function fetchFollowersPaginated(
  uid?: string,
  search?: string,
  lastDoc?: QueryDocumentSnapshot
) {
  if (!uid) {
    return Promise.resolve({ data: [], lastDoc: null });
  }

  return fetchPaginated(
    collection(db, "follows", uid, "followers"),
    search,
    lastDoc
  );
}

/* ---------- FOLLOWING ---------- */

export function fetchFollowingPaginated(
  uid?: string,
  search?: string,
  lastDoc?: QueryDocumentSnapshot
) {
  if (!uid) {
    return Promise.resolve({ data: [], lastDoc: null });
  }

  return fetchPaginated(
    collection(db, "follows", uid, "following"),
    search,
    lastDoc
  );
}

export async function getMyFollowData(myUid: string) {
  const followingSnap = await getDocs(
    collection(db, "follows", myUid, "following")
  );

  const followersSnap = await getDocs(
    collection(db, "follows", myUid, "followers")
  );

  return {
    followingIds: new Set(followingSnap.docs.map(d => d.id)),
    followerIds: new Set(followersSnap.docs.map(d => d.id)),
  };
}
