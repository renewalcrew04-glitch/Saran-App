export type Notification = {
  id: string;

  // receiver
  userId?: string;

  // sender
  fromUserId: string;
  fromUserName?: string;      // ✅ ADDED
  fromUserAvatar?: string;    // ✅ ADDED

  type:
    | "like"
    | "comment"
    | "reply"
    | "mention"
    | "tag"
    | "share"
    | "save"
    | "follow"
    | "dm";

  entityId?: string;
  entityType?: "post" | "comment" | "sframe" | "conversation";

  read: boolean;
  createdAt: any;
};
