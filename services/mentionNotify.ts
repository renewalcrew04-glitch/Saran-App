import { notify } from "@/services/notify";

export async function notifyMentions({
  mentionedUserIds,
  fromUserId,
  entityId,
  entityType,
}: {
  mentionedUserIds: string[];
  fromUserId: string;
  entityId: string;
  entityType: "post" | "comment" | "sframe";
}) {
  for (const uid of mentionedUserIds) {
    await notify({
      userId: uid,
      fromUserId,
      type: "mention",
      entityId,
      entityType,
      message: "mentioned you",
    });
  }
}
