# SARAN App - Migration to Flutter + Node.js Backend

This project has been migrated from **Expo/React Native with Firebase** to **Flutter with Node.js backend, MongoDB, and AWS**.

## 📁 Project Structure

```
SARAN/
├── backend/              # Node.js/Express REST API
│   ├── src/
│   │   ├── config/      # Database, AWS configuration
│   │   ├── controllers/ # Route controllers
│   │   ├── models/      # MongoDB models
│   │   ├── routes/      # API routes
│   │   └── server.js    # Entry point
│   ├── .gitlab-ci.yml   # GitLab CI/CD pipeline
│   └── package.json
│
├── flutter_app/         # Flutter mobile application
│   ├── lib/
│   │   ├── config/      # API configuration
│   │   ├── models/      # Data models
│   │   ├── services/    # API services
│   │   ├── providers/   # State management
│   │   ├── screens/     # UI screens
│   │   └── main.dart
│   └── pubspec.yaml
│
└── [old expo files]     # Legacy Expo/React Native code (can be removed)
```

## 🚀 Quick Start

### Backend Setup

1. **Navigate to backend:**
```bash
cd backend
```

2. **Install dependencies:**
```bash
npm install
```

3. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your MongoDB URI, AWS credentials, etc.
```

4. **Start the server:**
```bash
npm run dev
```

The API will be available at `http://localhost:3000`

### Flutter App Setup

1. **Navigate to Flutter app:**
```bash
cd flutter_app
```

2. **Get dependencies:**
```bash
flutter pub get
```

3. **Configure API endpoint:**
   - Edit `lib/config/api_config.dart`
   - Set `baseUrl` to your backend API URL

4. **Run the app:**
```bash
flutter run
```

## 📚 Documentation

- **[Backend README](backend/README.md)** - Backend API documentation
- **[Flutter README](flutter_app/README.md)** - Flutter app documentation
- **[Migration Guide](MIGRATION_GUIDE.md)** - Detailed migration documentation

## 🛠️ Tech Stack

### Backend
- **Node.js** + **Express.js** - REST API
- **MongoDB** - Database
- **AWS S3** - Media storage
- **JWT** - Authentication
- **GitLab CI/CD** - Continuous integration/deployment

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Provider/GetX** - State management
- **Dio** - HTTP client
- **GoRouter** - Navigation

## ☁️ Cloud Services

- **MongoDB Atlas** (or self-hosted) - Database
- **AWS S3** - Media file storage
- **AWS EC2/Elastic Beanstalk** - Backend hosting (optional)
- **GitLab** - Version control and CI/CD

## 🔐 Environment Variables

### Backend (.env)
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - JWT token secret
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_S3_BUCKET_NAME` - S3 bucket name
- `AWS_REGION` - AWS region
- `PORT` - Server port (default: 3000)

## 📝 Next Steps

1. **Set up MongoDB:**
   - Use MongoDB Atlas (cloud) or install locally
   - Update `MONGODB_URI` in backend `.env`

2. **Set up AWS S3:**
   - Create S3 bucket for media storage
   - Configure IAM user with S3 permissions
   - Add credentials to backend `.env`

3. **Configure GitLab CI/CD:**
   - Push code to GitLab repository
   - Add CI/CD variables in GitLab settings
   - Set up deployment pipeline

4. **Implement Features:**
   - Complete backend controllers with business logic
   - Implement Flutter services and UI screens
   - Add real-time features (Socket.io)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Submit a merge request

## 📄 License

ISC

---

**Note:** This is a migration from the original Expo/React Native app. See `MIGRATION_GUIDE.md` for detailed migration information.
# Test CI/CD
