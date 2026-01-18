# Migration Guide: Expo/React Native to Flutter + Node.js Backend

This guide documents the migration from Expo/React Native with Firebase to Flutter with Node.js backend, MongoDB, and AWS.

## 🎯 Migration Overview

### From:
- **Frontend**: Expo/React Native (TypeScript)
- **Backend**: Firebase (Firestore, Auth, Storage, Functions)
- **Database**: Firestore
- **Storage**: Firebase Storage

### To:
- **Frontend**: Flutter (Dart)
- **Backend**: Node.js/Express (REST API)
- **Database**: MongoDB
- **Storage**: AWS S3

## 📋 Project Structure

```
SARAN/
├── backend/              # Node.js/Express API
│   ├── src/
│   │   ├── config/      # Database, AWS config
│   │   ├── controllers/ # Route controllers
│   │   ├── models/      # MongoDB models
│   │   ├── routes/      # API routes
│   │   └── server.js
│   ├── .gitlab-ci.yml   # CI/CD
│   └── package.json
│
├── flutter_app/         # Flutter mobile app
│   ├── lib/
│   │   ├── models/     # Data models
│   │   ├── services/    # API services
│   │   ├── providers/   # State management
│   │   ├── screens/     # UI screens
│   │   └── main.dart
│   └── pubspec.yaml
│
└── [old expo files]     # Can be removed after migration
```

## 🔄 Key Changes

### 1. Authentication
**Before (Firebase):**
```typescript
import { signInWithEmailAndPassword } from 'firebase/auth';
await signInWithEmailAndPassword(auth, email, password);
```

**After (REST API + JWT):**
```dart
final response = await _authService.login(email, password);
final token = response['token'];
```

### 2. Database
**Before (Firestore):**
```typescript
import { collection, getDocs } from 'firebase/firestore';
const posts = await getDocs(collection(db, 'posts'));
```

**After (MongoDB via REST):**
```dart
final response = await _dio.get('/api/posts');
final posts = response.data;
```

### 3. Storage
**Before (Firebase Storage):**
```typescript
import { ref, uploadBytes } from 'firebase/storage';
await uploadBytes(storageRef, file);
```

**After (AWS S3):**
```javascript
// Backend generates presigned URL
const url = generatePresignedUploadUrl(key, contentType);
// Client uploads to S3 directly
```

### 4. State Management
**Before (Zustand):**
```typescript
const useAuthStore = create((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));
```

**After (Provider/GetX):**
```dart
class AuthProvider with ChangeNotifier {
  User? _user;
  // ...
}
```

## 🗄️ Data Model Mapping

### Users
- Firebase `profiles` collection → MongoDB `users` collection
- Same fields: uid, username, name, avatar, bio, etc.

### Posts
- Firebase `posts` collection → MongoDB `posts` collection
- Timestamp conversion: Firestore Timestamp → MongoDB Date

### Messages
- Firebase `conversations` → MongoDB `conversations` and `messages`
- Real-time via WebSockets (Socket.io)

### Notifications
- Firebase `notifications` → MongoDB `notifications`
- Push notifications via Firebase Cloud Messaging (still available)

## 🚀 Setup Steps

### Backend Setup

1. **Install Dependencies:**
```bash
cd backend
npm install
```

2. **Configure Environment:**
```bash
cp .env.example .env
# Edit .env with your MongoDB URI, AWS credentials, etc.
```

3. **Start MongoDB:**
```bash
# Local MongoDB
mongod

# Or use MongoDB Atlas (cloud)
# Update MONGODB_URI in .env
```

4. **Start Server:**
```bash
npm run dev
```

### Flutter Setup

1. **Install Flutter:**
```bash
# Follow Flutter installation guide for your OS
flutter --version
```

2. **Get Dependencies:**
```bash
cd flutter_app
flutter pub get
```

3. **Configure API:**
- Update `lib/config/api_config.dart` with backend URL

4. **Run App:**
```bash
flutter run
```

## ☁️ AWS Setup

1. **Create S3 Bucket:**
   - Go to AWS Console → S3
   - Create bucket: `saran-media-storage`
   - Configure CORS and permissions

2. **Create IAM User:**
   - Create IAM user with S3 access
   - Generate access keys
   - Add to `.env` file

3. **Optional - Deploy to EC2/Elastic Beanstalk:**
   - Use GitLab CI/CD or AWS CLI
   - See `.gitlab-ci.yml` for deployment config

## 📦 GitLab Setup

1. **Create Repository:**
   ```bash
   git remote add origin <gitlab-repo-url>
   git push -u origin main
   ```

2. **Configure CI/CD Variables:**
   - Go to GitLab → Settings → CI/CD → Variables
   - Add: `MONGODB_URI`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

3. **Push to Trigger Pipeline:**
   ```bash
   git push origin main
   ```

## 🔐 Security Checklist

- [ ] Change JWT_SECRET in production
- [ ] Use HTTPS in production
- [ ] Configure CORS properly
- [ ] Set up rate limiting (already configured)
- [ ] Use AWS IAM roles instead of access keys (production)
- [ ] Enable MongoDB authentication
- [ ] Use environment variables for all secrets

## 📝 Next Steps

1. **Implement Controllers:**
   - Complete placeholder controllers in `backend/src/controllers/`
   - Add business logic and validation

2. **Implement Flutter Services:**
   - Complete API services in `flutter_app/lib/services/`
   - Add error handling and retry logic

3. **Add Real-time Features:**
   - Set up Socket.io for real-time messaging
   - Implement WebSocket connections in Flutter

4. **Testing:**
   - Add unit tests for backend
   - Add widget tests for Flutter

5. **Deployment:**
   - Set up production MongoDB (Atlas)
   - Deploy backend to AWS
   - Build and publish Flutter app

## 🆘 Troubleshooting

### Backend Issues
- **MongoDB Connection:** Check MONGODB_URI format
- **AWS S3:** Verify IAM permissions and bucket name
- **JWT Errors:** Ensure JWT_SECRET is set

### Flutter Issues
- **API Connection:** Check API_BASE_URL in `api_config.dart`
- **Dependencies:** Run `flutter pub get`
- **Build Errors:** Check Flutter/Dart SDK versions

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Express.js Guide](https://expressjs.com/)
- [MongoDB Node.js Driver](https://docs.mongodb.com/drivers/node/)
- [AWS SDK for JavaScript](https://docs.aws.amazon.com/sdk-for-javascript/)
- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)

---

**Note:** This is a foundational setup. You'll need to implement the actual business logic in controllers and services based on your original Expo app's functionality.
