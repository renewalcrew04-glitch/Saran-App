import compression from 'compression';
import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { connectDB } from './config/database.js';
import "./jobs/spaceReminder.job.js";
import { errorHandler, notFound } from './middleware/errorMiddleware.js';
import eventReminderRoutes from "./routes/eventReminder.routes.js";

// Routes
import authRoutes from './routes/auth.routes.js';
import eventRoutes from './routes/event.routes.js';
import feedRoutes from './routes/feed.routes.js';
import messageRoutes from './routes/message.routes.js';
import notificationRoutes from './routes/notification.routes.js';
import postRoutes from './routes/post.routes.js';
import searchRoutes from './routes/search.routes.js';
import sframeRoutes from './routes/sframe.routes.js';
import sosRoutes from './routes/sos.routes.js';
import uploadRoutes from './routes/upload.routes.js';
import userRoutes from './routes/user.routes.js';
import wellnessRoutes from './routes/wellness.routes.js';

// Extra routes
import blockRoutes from "./routes/block.routes.js";
import closeFriendRoutes from "./routes/closeFriend.routes.js";
import contentMuteRoutes from "./routes/content_mute.routes.js";
import followRoutes from "./routes/follow.routes.js";
import hashtagRoutes from "./routes/hashtag.routes.js";
import mindJournalRoutes from "./routes/mindJournal.routes.js";
import muteRoutes from "./routes/mute.routes.js";
import reportRoutes from "./routes/report.routes.js";
import saveRoutes from "./routes/save.routes.js";
import settingsRoutes from "./routes/settings.routes.js";

// 🔑 SPACE ROUTES
import spaceRoutes from "./routes/space.routes.js";

dotenv.config();

const app = express();

// DB
connectDB();

// Security
app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));

// Rate limit
app.use(
  '/api/',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
  })
);

// Body
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(compression());

// Health
app.get('/health', (_, res) => {
  res.json({ status: 'OK', time: new Date().toISOString() });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/feed', feedRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/sframes', sframeRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/sos', sosRoutes);
app.use('/api/wellness', wellnessRoutes);
app.use('/api/upload', uploadRoutes);

app.use('/api/mind-journal', mindJournalRoutes);
app.use('/api/follow', followRoutes);
app.use('/api/block', blockRoutes);
app.use('/api/report', reportRoutes);
app.use('/api/save', saveRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/close-friends', closeFriendRoutes);
app.use('/api/mute', muteRoutes);
app.use('/api/hashtags', hashtagRoutes);
app.use('/api/content-mute', contentMuteRoutes);
app.use("/api/sframes", sframeRoutes);

// Event Reminders
app.use("/api/event-reminders", eventReminderRoutes);

// ✅ SPACE (FIXED)
app.use('/api/space', spaceRoutes);

// Static uploads
app.use('/uploads', express.static('uploads'));

// Errors
app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

export default app;