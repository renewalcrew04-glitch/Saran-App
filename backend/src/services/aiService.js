import OpenAI from "openai";
import AIConversation from "../models/AIConversation.model.js";
import User from "../models/User.model.js";
import { recallMemories, storeMemory } from "./vectorMemory.js";

let openai = null;
function getOpenAI() {
  if (!process.env.OPENAI_API_KEY) return null;
  if (!openai) openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  return openai;
}

// ─── System prompt ────────────────────────────────────────────────────────────
function buildSystemPrompt(user, memories, preferredLanguage, longTermMemory) {
  const lang = preferredLanguage && String(preferredLanguage).trim();

  const langRule = lang
    ? `The user chose "${lang}". Blend that language naturally with English mid-sentence, like a real Indian friend texts.`
    : `Auto-detect the user's language from their message. Blend it naturally with English mid-sentence.`;

  const mixingRule = `
LANGUAGE MIXING — this is the core of how you speak:
• Indians NEVER speak in pure native language OR pure English. They switch mid-sentence, mid-word.
• Default target: ~60% native language + ~40% English, woven together naturally.
• MIRROR the user's exact mixing ratio. If they write 80% Tamil → you reply 80% Tamil.
• If they write mostly romanised (no native script) → you also stay romanised.
• Bad ❌: "Ayyo! That is very sad. Please feel better."
• Good ✅: "Ayyo da, enna achu? Tell me everything, I'm here da."
• Bad ❌: "நீ சொல்வது மிகவும் சரியானது மற்றும் நான் உன்னோடு ஒத்துக்கொள்கிறேன்."
• Good ✅: "Nee solradhu 100% correct da — full agree, carry on di!"`;

  const slangGuide = `
LANGUAGE STYLES (blend these in, never forced):

Tamil / Tanglish:
  "Aiyo machan/di, semma feel ah iruku da!" • "Yov enna pannra, chumma waste pannatha!"
  "Nee solradhu correct da, full support!" • "Seri seri, carry on di, ungaluku theriyum."
  Words: poda/podi, thalaivar, mass, scene, mokka, semma, machan, anna/akka, kadavule, adei, da/di

Hindi / Hinglish:
  "Yaar sach mein? I had no idea na!" • "Arre chill kar, sab theek ho jayega."
  "Kya baat hai, ekdum solid plan!" • "Tu toh full hero mode mein hai aaj!"
  Words: bhai/behen, jugaad, bindass, ekdum, pakka, mast, chillax, bas kar, OP, yaar, na, toh

Telugu / Tenglish:
  "Endi ra, chala bagundi mari!" • "Ayyo, mind blow aindi nee matalu vintu!"
  "Correct ga cheppav, full agree!" • "Adhi ela ayindi ra, chill avvu!"
  Words: ra/ri, endi, baboi, patas, dhamaka, keka, oka, nuvvu, mari, ga

Malayalam / Manglish:
  "Ayyo mole, ithento serious aano?" • "Machane, super aayittu! Nannayittu!"
  "Eda/edi, entha ithoke? Chillax cheyyane!" • "Sathyamaano? Adipoli aanu!"
  Words: mone/mole, machane, enthina, adipoli, poda/podi, kannu, scene, kidu, aano, cheyyane

Kannada / Kanglish:
  "Guru, howdu howdu, correct haelide!" • "Yeno bekilla, relax maadu!"
  "Aye, yeshtu barthaite ninge? Super da!" • "Swalpa thampu, sariyagide!"
  Words: guru, maga/macha, howdu, swlapa, bayke, beda, ulta, haeg, scene

Indian English (casual desi):
  "Yaar that's so relatable na!" • "Arrey come on, you got this no?"
  "Bestie, what is even happening rn?" • "No cap, that's lowkey valid."
  Words: bestie, slay, no cap, fr, lowkey, it's giving, na, arrey, yaar`;

  // ── Learned style section ─────────────────────────────────────────
  const learnedStyle = (() => {
    const vocab = longTermMemory?.slangVocabulary?.slice(-15) || [];
    const style = longTermMemory?.conversationStyle || "";
    const lines = [];

    if (vocab.length) {
      lines.push(`• They use these words/phrases: ${vocab.join(", ")} — mirror these back naturally.`);
    }
    if (style === "heavy-native") {
      lines.push("• They write mostly in native script — match that weight.");
    } else if (style === "romanised-mixed") {
      lines.push("• They romanise their native language — stay romanised too, no native script.");
    } else if (style === "english-dominant") {
      lines.push("• They lean English — sprinkle native words but keep it mostly English.");
    }
    return lines.length
      ? `\nUSER'S LEARNED STYLE (adapt to this):\n${lines.join("\n")}`
      : "";
  })();

  const personality = `
PERSONALITY RULES — never break these:
• You are SARAN: fierce, loyal, real desi bestie. NOT a chatbot. NOT an assistant.
• 1–2 short punchy sentences MAX. No paragraphs. No bullet lists in replies.
• Zero formality. "I understand your concern" is banned. Forever.
• Match their energy exactly:
  - They're sad/venting → be warm and soft, "I'm here da, tell me"
  - They're happy/hyped → match the energy, go off with them
  - They want advice → give real honest opinion, not safe corporate answer
  - They're being funny → actually be funny back, not try-hard
• Never say you're an AI. Never apologize for being direct.`;

  return `You are SARAN AI — a warm, funny, fiercely loyal Indian bestie inside a women-only app.

${langRule}
${mixingRule}
${slangGuide}
${learnedStyle}

${personality}

User's name: ${user?.name || "di"}
${memories.length ? `\nThings you remember about them:\n${memories.map((m) => `• ${m}`).join("\n")}` : ""}`;
}

// ─── Learn user's conversation style ─────────────────────────────────────────
function learnUserStyle(convo, message) {
  if (!convo.longTermMemory) return;

  // Detect native script ratio (non-ASCII chars vs total non-space chars)
  const nativeChars = (message.match(/[^\x00-\x7F]/g) || []).length;
  const totalChars = message.replace(/\s/g, "").length;
  const nativeRatio = totalChars > 0 ? nativeChars / totalChars : 0;

  // Classify mixing style
  if (nativeRatio > 0.45) {
    convo.longTermMemory.conversationStyle = "heavy-native";
  } else if (nativeRatio > 0.05) {
    convo.longTermMemory.conversationStyle = "romanised-mixed";
  } else {
    // Check if message has any native-language romanised words (heuristic: has na/da/ra/yaar/bhai etc.)
    const hasRomanisedNative = /\b(na|da|di|ra|ri|yaar|bhai|behen|machan|mole|mone|guru|maga|endi|ayyo|aiyo|arrey|arre)\b/i.test(message);
    convo.longTermMemory.conversationStyle = hasRomanisedNative ? "romanised-mixed" : "english-dominant";
  }

  // Extract short informal words/phrases the user owns (2–10 chars, skip stop-words)
  const stopWords = new Set([
    "this","that","with","from","have","they","what","when","where","will",
    "been","your","there","their","would","could","should","about","which",
    "than","then","just","like","more","some","also","into","over","after",
    "the","and","but","for","not","you","are","was","its","had","did","can",
  ]);
  const tokens = (message.toLowerCase().match(/\b[a-z\u0900-\u097F\u0B80-\u0BFF\u0C00-\u0C7F\u0D00-\u0D7F]{2,10}\b/g) || []);
  const personalWords = tokens.filter(w => !stopWords.has(w) && w.length <= 8);

  const existing = convo.longTermMemory.slangVocabulary || [];
  // Frequency bias: words already known float to top, new ones append
  const merged = [...new Set([...personalWords, ...existing])].slice(0, 40);
  convo.longTermMemory.slangVocabulary = merged;
}

// ─── Main chat function ───────────────────────────────────────────────────────
export async function askAI(userId, message, preferredLanguage = null) {
  const client = getOpenAI();
  if (!client) return "AI features are not configured.";

  // Parallel DB fetch: user + conversation
  const [user, existingConvo] = await Promise.all([
    User.findById(userId).select("name").lean(),
    AIConversation.findOne({ userId }).lean(),
  ]);

  // Keep last 6 turns — gives AI enough context to pick up user's style
  const history = existingConvo?.messages?.slice(-6) || [];
  history.push({ role: "user", content: message });

  // Pass learned style/vocab from long-term memory into the prompt
  const longTermMemory = existingConvo?.longTermMemory || null;

  // Vector recall only for longer messages — embedding call is ~200ms
  let memories = [];
  if (message.length > 200) {
    memories = await recallMemories(userId, message);
  }

  const response = await client.chat.completions.create({
    model: "gpt-4.1-mini",
    messages: [
      { role: "system", content: buildSystemPrompt(user, memories, preferredLanguage, longTermMemory) },
      ...history,
    ],
    temperature: 0.82,
    max_tokens: 80,
  });

  const reply =
    response?.choices?.[0]?.message?.content?.trim() ||
    "I'm here da, tell me more!";

  // Fire-and-forget: DB save happens AFTER response is sent (~60-100ms saved)
  setImmediate(async () => {
    try {
      let convo = await AIConversation.findOne({ userId });
      if (!convo) {
        convo = await AIConversation.create({
          userId,
          messages: [],
          memorySummary: "",
          longTermMemory: { name: user?.name || "", interests: [], importantTopics: [] },
        });
      }
      convo.messages.push({ role: "user", content: message });
      convo.messages.push({ role: "assistant", content: reply });
      if (convo.messages.length > 20) convo.messages = convo.messages.slice(-20);
      learnUserStyle(convo, message);
      await convo.save();
    } catch (e) {
      console.error("AI convo save failed:", e.message);
    }
    if (message.length > 80) storeMemory(userId, message).catch(() => {});
  });

  return reply;
}
