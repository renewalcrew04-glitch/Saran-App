import OpenAI from "openai";
import AIConversation from "../models/AIConversation.model.js";
import User from "../models/User.model.js";
import { recallMemories, storeMemory } from "./vectorMemory.js";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

export async function askAI(userId, message) {

  const [user] = await Promise.all([
    User.findById(userId).select("name bio")
  ]);

  let convo = await AIConversation.findOne({ userId });

  if (!convo) {
    convo = await AIConversation.create({
      userId,
      messages: [],
      memorySummary: "",
      longTermMemory: {
        name: user?.name || "",
        interests: [],
        importantTopics: []
      }
    });
  }

  convo.messages.push({
    role: "user",
    content: message
  });

  const recentMessages = convo.messages.slice(-6);

  let memories = [];

  if (message.length > 120) {
    memories = await recallMemories(userId, message);
  }

  const systemPrompt = `
You are SARAN AI.

You are a friendly conversational AI companion inside a women-only Indian social platform.

IMPORTANT LANGUAGE RULES:

• Automatically detect the user's language.
• If the user speaks Tamil, reply in Tamil.
• If the user speaks Hindi, reply in Hindi.
• If the user mixes English + Indian language (Tanglish / Hinglish / Manglish), reply the same way.

CONVERSATION STYLE:

• Talk like a real supportive friend.
• Keep replies short (1–2 sentences).
• Avoid robotic tone.

User name: ${user?.name || "Unknown"}

Past memories:
${memories.join("\n")}
`;

  const messages = [
    { role: "system", content: systemPrompt },
    ...recentMessages
  ];

  const response = await openai.chat.completions.create({
    model: "gpt-4.1-mini",
    messages,
    temperature: 0.6,
    max_tokens: 40
  });

  const reply =
    response?.choices?.[0]?.message?.content ||
    "I'm here with you.";

  convo.messages.push({
    role: "assistant",
    content: reply
  });

  if (convo.messages.length > 20) {
    convo.messages = convo.messages.slice(-20);
  }

  await convo.save();

  if (message.length > 60) {
    storeMemory(userId, message).catch(()=>{});
  }

  return reply;
}