import { Notification } from "@/types/notification";

export function getNotificationText(n: Notification) {
  switch (n.type) {
    case "like":
      return "liked your post";
    case "comment":
      return "commented on your post";
    case "reply":
      return "replied to your comment";
    case "mention":
      return "mentioned you";
    case "tag":
      return "tagged you in a post";
    case "share":
      return "shared your post";
    case "save":
      return "saved your post";
    case "follow":
      return "started following you";
    case "live":
      return "is live now";
    default:
      return "";
  }
}
