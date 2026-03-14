import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

export async function analyzeMessage(message, recentMessages = []) {

  try {

    const context = recentMessages
      .map(m => m?.content || "")
      .join("\n");

    const result = await openai.chat.completions.create({
      model: "gpt-4.1-mini",
      temperature: 0,
      max_tokens: 120,
      messages: [
        {
          role: "system",
          content: `
You are analyzing messages from an Indian social app called SARAN.

Users may speak in:
- Tamil
- Hindi
- Telugu
- Malayalam
- Kannada
- Bengali
- English
- Mixed languages (Tanglish / Hinglish etc)

Your job is to analyze emotion and safety risk.

Return ONLY JSON.

Fields:

emotion
safety
interests
importantTopics
language
mixedLanguage

emotion values:
happy
sad
stressed
lonely
angry
excited
neutral

safety values:
normal
distress
relationship
self_harm
crisis

language values:
tamil
hindi
telugu
malayalam
kannada
bengali
english
unknown

mixedLanguage:
true or false

Example:

{
"emotion":"stressed",
"safety":"normal",
"interests":["movies"],
"importantTopics":["work"],
"language":"tamil",
"mixedLanguage":true
}
`
        },
        {
          role: "user",
          content: `
Conversation context:
${context}

User message:
${message}
`
        }
      ]
    });

    const raw = result?.choices?.[0]?.message?.content;

    if (!raw) return {};

    const jsonMatch = raw.match(/{[\s\S]*}/);

    if (!jsonMatch) return {};

    try {
      return JSON.parse(jsonMatch[0]);
    } catch {
      return {};
    }

  } catch (err) {

    console.log("AI analysis failed:", err.message);
    return {};

  }

}