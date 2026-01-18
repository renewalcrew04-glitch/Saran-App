import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

export const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/saran';
    
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
