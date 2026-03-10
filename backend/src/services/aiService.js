import OpenAI from "openai";
import AICompanionProfile from "../models/AICompanionProfile.model.js";
import AIConversation from "../models/AIConversation.model.js";
import User from "../models/User.model.js";
import { analyzeMessage } from "./aiBrain.js";
import { recallMemories, storeMemory } from "./vectorMemory.js";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

export async function askAI(userId, message) {

  const user = await User.findById(userId).select("name bio");
  const profile = await AICompanionProfile.findOne({ userId });

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

  // store user message
  convo.messages.push({
    role: "user",
    content: message
  });

  const recentMessages = convo.messages.slice(-6);

  // ---------- ANALYSIS + MEMORY ----------

  const [analysis, memories] = await Promise.all([
    analyzeMessage(message, recentMessages),
    message.length > 15
      ? recallMemories(userId, message)
      : Promise.resolve([])
  ]);

  const emotion = analysis.emotion || "neutral";
  const safetyLevel = analysis.safety || "normal";

  const interests = analysis.interests || [];
  const topics = analysis.importantTopics || [];

  // ---------- STORE INTERESTS ----------

  if (interests.length) {
    convo.longTermMemory.interests = [
      ...new Set([
        ...(convo.longTermMemory.interests || []),
        ...interests
      ])
    ];
  }

  // ---------- STORE TOPICS ----------

  if (topics.length) {
    convo.longTermMemory.importantTopics = [
      ...new Set([
        ...(convo.longTermMemory.importantTopics || []),
        ...topics
      ])
    ];
  }

  // ---------- SAFETY ----------

  if (safetyLevel === "self_harm" || safetyLevel === "crisis") {

    const safeReply = `
It sounds like you're going through something really heavy right now.

If you're in India you can reach out to:
Kiran Mental Health Helpline: 1800-599-0019

You don't have to go through this alone.
`;

    convo.messages.push({
      role: "assistant",
      content: safeReply
    });

    await convo.save();

    return safeReply;
  }

  // ---------- MOOD TRACKING ----------

  if (!convo.moodTimeline) convo.moodTimeline = [];

  convo.moodTimeline.push({
    mood: emotion,
    date: new Date()
  });

  if (convo.moodTimeline.length > 50) {
    convo.moodTimeline = convo.moodTimeline.slice(-50);
  }

  const moodPattern = detectMoodPattern(convo);

  // ---------- SYSTEM PROMPT ----------

  const systemPrompt = `
You are SARAN AI.

You are a friendly AI companion inside a women-only social platform.

Talk naturally like a real human friend.

Rules:

• Speak naturally like ChatGPT.
• Match the user's language automatically.
• If the user mixes languages (Tamil + English, Hindi + English etc), reply the same way.
• Mirror the user's tone and energy.
• Avoid robotic responses.
• Keep replies short unless user asks something detailed.

User info:
Name: ${user?.name || "Unknown"}

User interests:
${(convo.longTermMemory.interests || []).join(", ")}

Important topics in user's life:
${(convo.longTermMemory.importantTopics || []).join(", ")}

Past memories:
${memories.join("\n")}

Mood signal:
${moodPattern || "none"}

User personality summary:
${convo.memorySummary || "none"}
`;

  const messages = [
    { role: "system", content: systemPrompt },
    ...recentMessages
  ];

  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages,
    temperature: 0.7,
    max_tokens: 80
  });

  let reply =
    response.choices?.[0]?.message?.content ||
    "I'm here with you.";

  convo.messages.push({
    role: "assistant",
    content: reply
  });

  // limit history
  if (convo.messages.length > 20) {
    convo.messages = convo.messages.slice(-20);
  }

  await convo.save();

  // ---------- MEMORY SUMMARY ----------

  if (convo.messages.length % 20 === 0) {
    await updateMemorySummary(convo);
  }

  // ---------- VECTOR MEMORY ----------

  if (message.length > 20) {
    await storeMemory(userId, message);
  }

  if (reply.length > 20) {
    await storeMemory(userId, reply);
  }

  return reply;
}

// ---------- MOOD PATTERN ----------

function detectMoodPattern(convo) {

  if (!convo.moodTimeline) return null;

  const last = convo.moodTimeline.slice(-5);

  const stressed = last.filter(m => m.mood === "stressed").length;

  if (stressed >= 3) return "User seems stressed recently";

  const sad = last.filter(m => m.mood === "sad").length;

  if (sad >= 3) return "User seems emotionally low recently";

  return null;
}

// ---------- MEMORY SUMMARY ----------

async function updateMemorySummary(convo) {

  const text = convo.messages
    .map(m => `${m.role}: ${m.content}`)
    .join("\n");

  const result = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0.3,
    messages: [
      { role: "system", content: "Summarize the user's personality and important traits." },
      { role: "user", content: text }
    ]
  });

  convo.memorySummary =
    result.choices?.[0]?.message?.content || "";

  await convo.save();
}
