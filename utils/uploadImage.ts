import { getDownloadURL, ref, uploadBytesResumable } from "firebase/storage";
import { storage, auth } from "@/services/firebase";
import * as ImageManipulator from "expo-image-manipulator";

/**
 * ✅ Expo-safe upload
 * ✅ Retry support
 * ✅ Resume while app is alive
 * ❌ True background upload (Expo limitation)
 */
export async function uploadMediaAsync(
  uri: string,
  folder: "profile" | "posts" | "sframes",
  mimeType?: string,
  onProgress?: (p: number) => void
) {
  const user = auth.currentUser;
  if (!user) throw new Error("User not authenticated");

  let uploadUri = uri;

  // 🔹 Compress images only
  if (mimeType?.startsWith("image")) {
    const result = await ImageManipulator.manipulateAsync(uri, [], {
      compress: 0.8,
      format: ImageManipulator.SaveFormat.JPEG,
    });
    uploadUri = result.uri;
  }

  const response = await fetch(uploadUri);
  const blob = await response.blob();

  const extension =
    mimeType?.includes("video") ? "mp4" :
    mimeType?.includes("png") ? "png" : "jpg";

  const filename = `${Date.now()}.${extension}`;
  const storageRef = ref(storage, `${folder}/${user.uid}/${filename}`);

  let attempt = 0;
  const MAX_RETRIES = 2;

  while (attempt <= MAX_RETRIES) {
    try {
      const uploadTask = uploadBytesResumable(storageRef, blob, {
        contentType: mimeType || blob.type || "application/octet-stream",
        cacheControl: "public,max-age=31536000",
      });

      uploadTask.on("state_changed", snapshot => {
        if (onProgress && snapshot.totalBytes > 0) {
          const percent =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          onProgress(Math.round(percent));
        }
      });

      await uploadTask;
      return await getDownloadURL(storageRef);
    } catch (e) {
      attempt++;
      if (attempt > MAX_RETRIES) throw e;
      await new Promise(r => setTimeout(r, 1200));
    }
  }

  throw new Error("Upload failed");
}
