# SARAN Development Roadmap

This document outlines the development tasks to complete the migration and build out features.

## ✅ Completed

- [x] Backend structure created (Node.js/Express)
- [x] MongoDB models created (User, Post, Notification, Message, Event, SFrame, etc.)
- [x] Routes structure created
- [x] Authentication controller implemented
- [x] MongoDB Atlas connection configured
- [x] AWS S3 bucket created and configured
- [x] IAM user created for S3 access
- [x] Flutter project structure created
- [x] Basic Flutter screens created
- [x] GitLab CI/CD configuration created

## 🚧 In Progress

- [ ] Implement remaining backend controllers
- [ ] Complete Flutter app implementation
- [ ] Set up GitLab repository and CI/CD

## 📋 Backend Tasks

### Priority 1: Core Controllers

#### User Controller (`src/controllers/user.controller.js`)
- [ ] `getUserProfile` - Get user profile by UID
- [ ] `updateUserProfile` - Update user profile
- [ ] `followUser` - Follow a user
- [ ] `unfollowUser` - Unfollow a user
- [ ] `getFollowers` - Get user's followers list
- [ ] `getFollowing` - Get user's following list
- [ ] `searchUsers` - Search users by username/name

#### Post Controller (`src/controllers/post.controller.js`)
- [ ] `createPost` - Create new post (text, photo, video)
- [ ] `getPost` - Get single post by ID
- [ ] `updatePost` - Update post
- [ ] `deletePost` - Soft delete post
- [ ] `likePost` - Like a post
- [ ] `unlikePost` - Unlike a post
- [ ] `repost` - Repost a post
- [ ] `quotePost` - Quote repost with comment
- [ ] `getComments` - Get post comments
- [ ] `addComment` - Add comment to post

#### Feed Controller (`src/controllers/feed.controller.js`)
- [ ] `getHomeFeed` - Get personalized home feed
- [ ] `getUserFeed` - Get user's posts feed
- [ ] `getExploreFeed` - Get explore/discover feed

### Priority 2: Messaging & Notifications

#### Message Controller (`src/controllers/message.controller.js`)
- [ ] `getConversations` - Get all conversations
- [ ] `getConversation` - Get conversation messages
- [ ] `sendMessage` - Send message (text, image, voice)
- [ ] `markAsRead` - Mark messages as read
- [ ] `deleteConversation` - Delete conversation

#### Notification Controller (`src/controllers/notification.controller.js`)
- [ ] `getNotifications` - Get user notifications
- [ ] `markAsRead` - Mark notification as read
- [ ] `markAllAsRead` - Mark all as read
- [ ] `deleteNotification` - Delete notification

### Priority 3: Additional Features

#### Event Controller (`src/controllers/event.controller.js`)
- [ ] `createEvent` - Create event
- [ ] `getEvent` - Get event details
- [ ] `updateEvent` - Update event
- [ ] `deleteEvent` - Delete event
- [ ] `getEvents` - Get events list
- [ ] `attendEvent` - Attend event
- [ ] `unattendEvent` - Unattend event

#### SFrame Controller (`src/controllers/sframe.controller.js`)
- [ ] `createSFrame` - Create story-like content
- [ ] `getSFrames` - Get active SFrames
- [ ] `getSFrame` - Get single SFrame
- [ ] `viewSFrame` - Mark SFrame as viewed
- [ ] `echoSFrame` - Echo/react to SFrame

#### Search Controller (`src/controllers/search.controller.js`)
- [ ] `searchPosts` - Search posts
- [ ] `searchUsers` - Search users
- [ ] `searchAll` - Combined search

#### SOS Controller (`src/controllers/sos.controller.js`)
- [ ] `createSOS` - Create SOS emergency
- [ ] `getSOS` - Get SOS details
- [ ] `updateSOSLocation` - Update SOS location
- [ ] `resolveSOS` - Resolve SOS

#### Wellness Controller (`src/controllers/wellness.controller.js`)
- [ ] `getWellnessStreak` - Get wellness streak
- [ ] `updateWellnessActivity` - Update wellness activity
- [ ] `getWellnessStats` - Get wellness statistics

### Priority 4: AWS S3 Integration

- [ ] Implement presigned URL generation for uploads
- [ ] Add file upload endpoint
- [ ] Add image/video processing
- [ ] Implement upload queue/resume functionality

### Priority 5: Real-time Features

- [ ] Set up Socket.io for real-time messaging
- [ ] Implement WebSocket connections
- [ ] Add real-time notifications
- [ ] Add typing indicators

## 📱 Flutter App Tasks

### Priority 1: Core Features

#### Authentication
- [ ] Complete login screen
- [ ] Complete signup screen
- [ ] Implement forgot password
- [ ] Add token storage (secure storage)
- [ ] Add auto-login on app start

#### Home Feed
- [ ] Implement feed list
- [ ] Add pull-to-refresh
- [ ] Add infinite scroll
- [ ] Implement post cards
- [ ] Add like/comment/repost actions

#### Profile
- [ ] User profile screen
- [ ] Edit profile screen
- [ ] Followers/Following lists
- [ ] User posts grid
- [ ] Settings screens

### Priority 2: Social Features

#### Posts
- [ ] Create post screen
- [ ] Image/video picker
- [ ] Post detail screen
- [ ] Comments screen
- [ ] Repost/Quote functionality

#### Messages
- [ ] Conversations list
- [ ] Chat screen
- [ ] Image sharing
- [ ] Voice messages
- [ ] Read receipts

#### Explore
- [ ] Explore feed
- [ ] Search functionality
- [ ] People discovery
- [ ] Category filters

### Priority 3: Special Features

#### Events
- [ ] Event list
- [ ] Event details
- [ ] Create event
- [ ] Attend/unattend

#### SFrames (Stories)
- [ ] SFrame viewer
- [ ] Create SFrame
- [ ] SFrame list

#### SOS
- [ ] SOS button
- [ ] Location sharing
- [ ] Emergency contacts

#### Wellness
- [ ] Wellness dashboard
- [ ] Streak tracking
- [ ] Activity logging
- [ ] Wellness games

### Priority 4: UI/UX

- [ ] Implement theme (light/dark mode)
- [ ] Add animations
- [ ] Improve loading states
- [ ] Add error handling
- [ ] Implement offline support
- [ ] Add pull-to-refresh everywhere
- [ ] Optimize images (caching)

## 🔧 Infrastructure Tasks

### GitLab Setup
- [ ] Push code to GitLab
- [ ] Configure CI/CD variables
- [ ] Set up branch protection
- [ ] Configure merge request templates

### AWS Deployment
- [ ] Set up EC2 instance or Elastic Beanstalk
- [ ] Configure domain name
- [ ] Set up SSL certificate
- [ ] Configure load balancer (if needed)
- [ ] Set up monitoring and logging

### MongoDB
- [ ] Set up indexes for performance
- [ ] Configure backups
- [ ] Set up monitoring
- [ ] Optimize queries

## 📊 Testing Tasks

### Backend
- [ ] Unit tests for controllers
- [ ] Integration tests for API endpoints
- [ ] Test authentication flow
- [ ] Test file uploads
- [ ] Load testing

### Flutter
- [ ] Widget tests
- [ ] Integration tests
- [ ] UI tests
- [ ] Performance testing

## 📝 Documentation Tasks

- [ ] API documentation (Swagger/OpenAPI)
- [ ] Flutter app documentation
- [ ] Deployment guide
- [ ] Contributing guide
- [ ] Architecture documentation

## 🎯 Quick Wins (Start Here)

1. **Complete User Controller** - Most basic functionality
2. **Complete Post Controller** - Core feature
3. **Implement Flutter Login** - Get app working
4. **Set up GitLab** - Version control
5. **Add API documentation** - Help with development

## 📅 Suggested Timeline

### Week 1-2: Backend Core
- Complete User, Post, Feed controllers
- Implement authentication flow
- Set up AWS S3 uploads

### Week 3-4: Flutter Core
- Complete authentication screens
- Implement home feed
- Add profile screens

### Week 5-6: Additional Features
- Messages, Notifications
- Events, SFrames
- Search functionality

### Week 7-8: Polish & Deploy
- Testing
- Bug fixes
- Deployment setup
- Documentation

## 🚀 Getting Started

1. Pick a task from Priority 1
2. Create a feature branch: `git checkout -b feature/task-name`
3. Implement the feature
4. Test it
5. Commit and push: `git commit -m "Add feature X" && git push`
6. Create merge request in GitLab

---

**Note**: This is a living document. Update it as you complete tasks and discover new requirements.
