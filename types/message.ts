export type Reaction = "❤️" | "😂" | "👍" | "😮";

export type Message = {
  id: string;
  senderUid: string;
  receiverUid: string;
  text?: string;
  imageUrl?: string;
  type: "text" | "image" | "voice";
  voiceUrl?: string;
  read: boolean;
  reactions?: Record<string, Reaction>;
  createdAt: any;
};
