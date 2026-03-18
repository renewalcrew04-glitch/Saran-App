import jwt from 'jsonwebtoken';
import User from '../models/User.model.js';

// userId (string) → Set of socketIds (one user can have multiple tabs/devices)
const onlineUsers = new Map();

export const getSocketIds = (userId) => {
  return onlineUsers.get(userId.toString()) || new Set();
};

export const isUserOnline = (userId) => {
  const sockets = onlineUsers.get(userId.toString());
  return sockets && sockets.size > 0;
};

export const emitToUser = (io, userId, event, data) => {
  const socketIds = getSocketIds(userId);
  socketIds.forEach((sid) => io.to(sid).emit(event, data));
};

export const initSocket = (io) => {
  // ── Auth middleware ──────────────────────────────────────────
  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) return next(new Error('No token'));

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).select('_id username name avatar');
      if (!user) return next(new Error('User not found'));

      socket.userId = user._id.toString();
      socket.user = user;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  // ── Connection ───────────────────────────────────────────────
  io.on('connection', async (socket) => {
    const userId = socket.userId;

    // Track online socket
    if (!onlineUsers.has(userId)) onlineUsers.set(userId, new Set());
    onlineUsers.get(userId).add(socket.id);

    // Mark user online in DB
    await User.findByIdAndUpdate(userId, { online: true });

    // Broadcast to everyone that this user came online
    socket.broadcast.emit('user_online', { userId });

    // ── Join a conversation room ─────────────────────────────
    socket.on('join_conversation', ({ conversationId }) => {
      if (conversationId) socket.join(`conv:${conversationId}`);
    });

    socket.on('leave_conversation', ({ conversationId }) => {
      if (conversationId) socket.leave(`conv:${conversationId}`);
    });

    // ── Typing indicator ─────────────────────────────────────
    socket.on('typing', ({ conversationId, isTyping }) => {
      socket.to(`conv:${conversationId}`).emit('typing', {
        conversationId,
        userId,
        isTyping: !!isTyping,
      });
    });

    // ── Disconnect ───────────────────────────────────────────
    socket.on('disconnect', async () => {
      const sockets = onlineUsers.get(userId);
      if (sockets) {
        sockets.delete(socket.id);
        if (sockets.size === 0) {
          onlineUsers.delete(userId);
          await User.findByIdAndUpdate(userId, {
            online: false,
            lastSeen: new Date(),
          });
          socket.broadcast.emit('user_offline', {
            userId,
            lastSeen: new Date(),
          });
        }
      }
    });
  });
};
