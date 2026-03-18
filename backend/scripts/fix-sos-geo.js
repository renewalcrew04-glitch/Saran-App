/**
 * One-time fix: Remove invalid location from SOS documents
 * (location with type "Point" but no coordinates causes "Can't extract geo keys")
 * Run from backend folder: node scripts/fix-sos-geo.js
 * Or run the MongoDB command below in Atlas Shell.
 */
import 'dotenv/config';
import mongoose from 'mongoose';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

async function main() {
  let uri = process.env.MONGODB_URI;
  if (!uri && process.cwd().endsWith('backend')) {
    try {
      const env = readFileSync(join(process.cwd(), '.env'), 'utf8');
      const m = env.match(/MONGODB_URI=(.+)/);
      if (m) uri = m[1].trim();
    } catch (_) {}
  }
  if (!uri) {
    console.error('Set MONGODB_URI in .env or environment');
    process.exit(1);
  }

  await mongoose.connect(uri);
  const db = mongoose.connection.db;
  const result = await db.collection('sos').updateMany(
    {
      'location.type': 'Point',
      $or: [
        { 'location.coordinates': null },
        { 'location.coordinates': { $exists: false } },
        { 'location.coordinates': { $size: 0 } },
      ],
    },
    { $unset: { location: 1 } }
  );
  console.log('Fixed SOS documents:', result.modifiedCount);
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
