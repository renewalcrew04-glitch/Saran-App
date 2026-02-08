import mongoose from 'mongoose';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// Load .env from backend root (one level up from src/); fallback to cwd (e.g. when PM2 runs from backend)
const envPathBackend = path.resolve(__dirname, '../../.env');
const envPathCwd = path.resolve(process.cwd(), '.env');
const result = dotenv.config({ path: envPathBackend }) ?? dotenv.config({ path: envPathCwd });
if (!process.env.MONGODB_URI && result?.error) {
  console.warn('⚠️ Could not load .env from', envPathBackend, 'or', envPathCwd);
}

export const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/saran';
    if (!process.env.MONGODB_URI) {
      console.warn('⚠️ MONGODB_URI not set in .env, using localhost');
    }
    
    // Removed deprecated options: useNewUrlParser and useUnifiedTopology
    // These are no longer needed in Mongoose 6+ and MongoDB Driver 4+
    const conn = await mongoose.connect(mongoUri);

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    console.error('💡 Make sure MongoDB is running or check your MONGODB_URI in .env');
    
    // In development, don't exit immediately - allow server to start
    // but it won't be able to handle DB operations
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }
};

// Handle connection events
mongoose.connection.on('disconnected', () => {
  console.log('MongoDB disconnected');
});

mongoose.connection.on('error', (err) => {
  console.error('MongoDB connection error:', err);
});
