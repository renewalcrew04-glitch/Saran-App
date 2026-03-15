/**
 * One-time script: Set gender to 'female' for the manoji account (for testing).
 * Run from backend folder: node scripts/set-user-gender.js
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

  // Load User model (same as server)
  const User = (await import('../src/models/User.model.js')).default;

  // Try username (lowercase) or email
  let user = await User.findOne({ username: 'manoji' });
  if (!user) user = await User.findOne({ username: /manoji/i });
  if (!user) user = await User.findOne({ email: 'drmanomc0007@gmail.com' });
  if (!user) {
    const any = await User.findOne().select('username email');
    console.error('User "manoji" or drmanomc0007@gmail.com not found. Example user in DB:', any?.username, any?.email);
    await mongoose.disconnect();
    process.exit(1);
  }

  user.gender = 'female';
  await user.save();

  console.log('Updated user', user.username, '- gender set to female');
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
