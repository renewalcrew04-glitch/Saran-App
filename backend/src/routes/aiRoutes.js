import express from "express";
import multer from "multer";
import OpenAI, { toFile } from "openai";
import { protect } from "../middleware/auth.middleware.js";
import { askAI } from "../services/aiService.js";

const router = express.Router();

// Multer: memory storage for audio uploads (no disk I/O)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB (Whisper limit)
});

let openai = null;
function getOpenAI() {
  if (!process.env.OPENAI_API_KEY) return null;
  if (!openai) openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  return openai;
}

// Per-user cooldown for chat (300ms debounce)
const userCooldown = new Map();

// ─── POST /api/ai/chat ────────────────────────────────────────────────────────
router.post("/chat", protect, async (req, res) => {
  try {
    const userId = req.user._id.toString();
    const { message, language } = req.body;

    if (!message) {
      return res.status(400).json({ success: false, message: "Message required" });
    }

    const now = Date.now();
    if (now - (userCooldown.get(userId) || 0) < 300) {
      return res.json({ success: true, reply: "..." });
    }
    userCooldown.set(userId, now);

    const reply = await askAI(userId, message, language);
    res.json({ success: true, reply });
  } catch (err) {
    console.error("AI chat error:", err);
    res.status(500).json({ success: false, message: "AI failed" });
  }
});

// ─── POST /api/ai/stt ─────────────────────────────────────────────────────────
// Speech-to-Text using OpenAI Whisper
// Body: multipart/form-data with field "audio" (m4a / webm / mp3 / wav / ogg)
// Returns: { success: true, text: "transcribed text" }
router.post("/stt", protect, upload.single("audio"), async (req, res) => {
  try {
    const client = getOpenAI();
    if (!client) {
      return res.status(503).json({ success: false, message: "AI not configured" });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, message: "audio file required" });
    }

    // Convert buffer to a File-like object for the OpenAI SDK
    const ext = (req.file.originalname || "audio.m4a").split(".").pop() || "m4a";
    const filename = `audio.${ext}`;
    const audioFile = await toFile(req.file.buffer, filename, {
      type: req.file.mimetype || "audio/m4a",
    });

    const transcript = await client.audio.transcriptions.create({
      model: "whisper-1",
      file: audioFile,
      // Let Whisper auto-detect language — handles all Indian languages
    });

    res.json({ success: true, text: transcript.text });
  } catch (err) {
    console.error("STT error:", err);
    res.status(500).json({ success: false, message: "Speech recognition failed" });
  }
});

// ─── POST /api/ai/tts ─────────────────────────────────────────────────────────
// Text-to-Speech using OpenAI TTS
// Body: { text: string, voice?: "nova"|"alloy"|"echo"|"fable"|"onyx"|"shimmer" }
// Returns: audio/mpeg binary stream
router.post("/tts", protect, async (req, res) => {
  try {
    const client = getOpenAI();
    if (!client) {
      return res.status(503).json({ success: false, message: "AI not configured" });
    }

    const { text, voice = "nova" } = req.body;
    if (!text || text.trim().length === 0) {
      return res.status(400).json({ success: false, message: "text is required" });
    }
    if (text.length > 4096) {
      return res.status(400).json({ success: false, message: "text too long (max 4096 chars)" });
    }

    const allowedVoices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"];
    const safeVoice = allowedVoices.includes(voice) ? voice : "nova";

    const response = await client.audio.speech.create({
      model: "tts-1",      // tts-1 is faster; use tts-1-hd for higher quality
      voice: safeVoice,
      input: text.trim(),
      response_format: "mp3",
    });

    const buffer = Buffer.from(await response.arrayBuffer());
    res.set("Content-Type", "audio/mpeg");
    res.set("Content-Length", buffer.length);
    res.send(buffer);
  } catch (err) {
    console.error("TTS error:", err);
    res.status(500).json({ success: false, message: "Text-to-speech failed" });
  }
});

export default router;
