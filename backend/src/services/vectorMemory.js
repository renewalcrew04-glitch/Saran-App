import OpenAI from "openai";
import AIMemory from "../models/AIMemory.model.js";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

export async function storeMemory(userId, text) {

  try {

    if (!text || text.length < 80) return;

    const embed = await openai.embeddings.create({
      model: "text-embedding-3-small",
      input: text
    });

    const vector = embed.data[0].embedding;

    await AIMemory.create({
      userId,
      text,
      embedding: vector
    });

  } catch (err) {

    console.log("Vector memory store failed");

  }

}

export async function recallMemories(userId, message) {

  try {

    const embed = await openai.embeddings.create({
      model: "text-embedding-3-small",
      input: message
    });

    const queryVector = embed.data[0].embedding;

    const memories = await AIMemory
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(50);

    let scored = memories
      .filter(mem => mem.embedding)
      .map(mem => {

        const score = cosineSimilarity(queryVector, mem.embedding);

        return {
          text: mem.text,
          score
        };

      });

    scored.sort((a,b)=>b.score-a.score);

    return scored.slice(0,3).map(m => m.text);

  } catch (err) {

    console.log("Vector recall failed");

    return [];

  }

}

function cosineSimilarity(a,b){

  let dot = 0;
  let normA = 0;
  let normB = 0;

  for(let i=0;i<a.length;i++){

    dot += a[i]*b[i];
    normA += a[i]*a[i];
    normB += b[i]*b[i];

  }

  return dot/(Math.sqrt(normA)*Math.sqrt(normB));

}