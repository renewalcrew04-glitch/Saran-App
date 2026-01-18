# SARAN Backend API

RESTful API backend for SARAN App built with Node.js, Express, MongoDB, and AWS.

## 🚀 Features

- **Authentication & Authorization** - JWT-based auth system
- **User Management** - Profile, follow/unfollow, search
- **Posts** - Create, read, update, delete posts with media
- **Feed** - Home feed, explore, user feeds
- **Messaging** - Direct messages, conversations
- **Notifications** - Real-time notifications
- **Events** - Event creation and management
- **SFrames** - Story-like temporary content
- **SOS** - Emergency location sharing
- **Wellness** - Wellness tracking and streaks
- **Search** - Full-text search for posts and users
- **AWS Integration** - S3 for media storage

## 📋 Prerequisites

- Node.js >= 18.0.0
- MongoDB (local or Atlas)
- AWS Account (for S3 storage)
- GitLab account (for CI/CD)

## 🛠️ Installation

1. Clone the repository:
```bash
git clone <gitlab-repo-url>
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Configure environment variables in `.env`:
   - `MONGODB_URI` - MongoDB connection string
   - `JWT_SECRET` - Secret key for JWT tokens
   - `AWS_ACCESS_KEY_ID` - AWS access key
   - `AWS_SECRET_ACCESS_KEY` - AWS secret key
   - `AWS_S3_BUCKET_NAME` - S3 bucket name

5. Start the server:
```bash
# Development
npm run dev

# Production
npm start
```

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/         # Configuration files (database, AWS)
│   ├── controllers/    # Route controllers
│   ├── middleware/     # Custom middleware (auth, error handling)
│   ├── models/         # MongoDB models
│   ├── routes/         # API routes
│   └── server.js       # Entry point
├── .env.example        # Environment variables template
├── .gitlab-ci.yml      # GitLab CI/CD configuration
├── package.json        # Dependencies
└── README.md           # This file
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update profile

### Users
- `GET /api/users/:uid` - Get user profile
- `POST /api/users/:uid/follow` - Follow user
- `DELETE /api/users/:uid/follow` - Unfollow user

### Posts
- `POST /api/posts` - Create post
- `GET /api/posts/:id` - Get post
- `PUT /api/posts/:id` - Update post
- `DELETE /api/posts/:id` - Delete post
- `POST /api/posts/:id/like` - Like post

### Feed
- `GET /api/feed/home` - Get home feed
- `GET /api/feed/user/:uid` - Get user feed
- `GET /api/feed/explore` - Get explore feed

## 🔐 Authentication

All protected routes require a JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

## 🗄️ Database

MongoDB is used as the primary database. Key collections:
- `users` - User profiles
- `posts` - Posts content
- `follows` - Follow relationships
- `messages` - Direct messages
- `notifications` - User notifications
- `events` - Events
- `sframes` - Temporary story content

## ☁️ AWS Integration

- **S3** - Media storage (images, videos)
- **EC2/Elastic Beanstalk** - Server deployment (optional)

## 🚢 Deployment

### GitLab CI/CD

The project includes `.gitlab-ci.yml` for automated CI/CD:

1. **Test Stage** - Runs tests on merge requests
2. **Build Stage** - Builds the application
3. **Deploy Stage** - Deploys to AWS (manual trigger)

### Manual Deployment

1. Set up AWS credentials in GitLab CI/CD variables:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `MONGODB_URI`

2. Push to `main` branch to trigger deployment

## 📝 Environment Variables

See `.env.example` for all required environment variables.

## 🧪 Testing

```bash
npm test
```

## 📄 License

ISC

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Submit a merge request
