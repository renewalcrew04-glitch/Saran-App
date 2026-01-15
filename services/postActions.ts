import { db, auth } from "@/services/firebase";
import {
  doc,
  setDoc,
  deleteDoc,
  addDoc,
  collection,
  serverTimestamp,
  onSnapshot,
  runTransaction,
  increment,
} from "firebase/firestore";

/* =================================================
   ❤️ LIKE (WITH COUNT UPDATE)
================================================= */

export async function likePost(postId: string, postOwnerId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  const postRef = doc(db, "posts", postId);
  const likeRef = doc(db, "posts", postId, "likes", uid);

  await runTransaction(db, async (tx) => {
    const likeSnap = await tx.get(likeRef);

    // already liked -> do nothing
    if (likeSnap.exists()) return;

    tx.set(likeRef, {
      uid,
      postOwnerId,
      createdAt: serverTimestamp(),
    });

    tx.update(postRef, {
      likesCount: increment(1),
    });
  });
}

export async function unlikePost(postId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  const postRef = doc(db, "posts", postId);
  const likeRef = doc(db, "posts", postId, "likes", uid);

  await runTransaction(db, async (tx) => {
    const likeSnap = await tx.get(likeRef);

    // not liked -> do nothing
    if (!likeSnap.exists()) return;

    tx.delete(likeRef);

    tx.update(postRef, {
      likesCount: increment(-1),
    });
  });
}

/* =================================================
   💬 COMMENT (WITH COUNT UPDATE)
================================================= */

export async function commentPost(postId: string, text: string) {
  const uid = auth.currentUser?.uid;
  if (!uid || !text.trim()) return;

  const postRef = doc(db, "posts", postId);
  const commentsCol = collection(db, "posts", postId, "comments");

  await runTransaction(db, async (tx) => {
    const newCommentRef = doc(commentsCol);

    tx.set(newCommentRef, {
      uid,
      text: text.trim(),
      createdAt: serverTimestamp(),
    });

    tx.update(postRef, {
      commentsCount: increment(1),
    });
  });
}

/* =================================================
   🔁 REPOST (WITH COUNT UPDATE)
================================================= */

export async function repostPost(postId: string, postOwnerId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  const postRef = doc(db, "posts", postId);
  const repostRef = doc(db, "posts", postId, "reposts", uid);

  await runTransaction(db, async (tx) => {
    const repostSnap = await tx.get(repostRef);

    // already reposted -> do nothing
    if (repostSnap.exists()) return;

    tx.set(repostRef, {
      uid,
      postOwnerId,
      createdAt: serverTimestamp(),
    });

    tx.update(postRef, {
      repostsCount: increment(1),
    });
  });
}

export async function unrepostPost(postId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  const postRef = doc(db, "posts", postId);
  const repostRef = doc(db, "posts", postId, "reposts", uid);

  await runTransaction(db, async (tx) => {
    const repostSnap = await tx.get(repostRef);

    // not reposted -> do nothing
    if (!repostSnap.exists()) return;

    tx.delete(repostRef);

    tx.update(postRef, {
      repostsCount: increment(-1),
    });
  });
}

/* =================================================
   📤 SHARE (WITH COUNT UPDATE)
================================================= */

export async function sharePost(postId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  const postRef = doc(db, "posts", postId);
  const shareRef = doc(db, "posts", postId, "shares", uid);

  await runTransaction(db, async (tx) => {
    const shareSnap = await tx.get(shareRef);

    // already shared -> do nothing
    if (shareSnap.exists()) return;

    tx.set(shareRef, {
      uid,
      createdAt: serverTimestamp(),
    });

    tx.update(postRef, {
      sharesCount: increment(1),
    });
  });
}

/* =================================================
   📊 REAL-TIME POST STATS (KEEP)
================================================= */

export function subscribePostStats(
  postId: string,
  callback: (stats: {
    likes: number;
    comments: number;
    reposts: number;
    shares: number;
    likedByMe: boolean;
    repostedByMe: boolean;
  }) => void
) {
  const uid = auth.currentUser?.uid;

  let state = {
    likes: 0,
    comments: 0,
    reposts: 0,
    shares: 0,
    likedByMe: false,
    repostedByMe: false,
  };

  function emit() {
    callback({ ...state });
  }

  const unsubLikes = onSnapshot(
    collection(db, "posts", postId, "likes"),
    (snap) => {
      state.likes = snap.size;
      state.likedByMe = uid ? snap.docs.some((d) => d.id === uid) : false;
      emit();
    }
  );

  const unsubComments = onSnapshot(
    collection(db, "posts", postId, "comments"),
    (snap) => {
      state.comments = snap.size;
      emit();
    }
  );

  const unsubReposts = onSnapshot(
    collection(db, "posts", postId, "reposts"),
    (snap) => {
      state.reposts = snap.size;
      state.repostedByMe = uid ? snap.docs.some((d) => d.id === uid) : false;
      emit();
    }
  );

  const unsubShares = onSnapshot(
    collection(db, "posts", postId, "shares"),
    (snap) => {
      state.shares = snap.size;
      emit();
    }
  );

  return () => {
    unsubLikes();
    unsubComments();
    unsubReposts();
    unsubShares();
  };
}
