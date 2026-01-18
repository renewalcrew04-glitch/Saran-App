# MongoDB Setup Guide

The server is trying to connect to MongoDB but can't find it. Here are your options:

## Option 1: Install MongoDB Locally (Recommended for Development)

### macOS (using Homebrew):
```bash
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```

### Verify Installation:
```bash
mongod --version
```

### Start MongoDB:
```bash
# Start as a service (auto-start on boot)
brew services start mongodb-community

# Or start manually
mongod --config /opt/homebrew/etc/mongod.conf
```

### Test Connection:
```bash
mongosh
# Should connect successfully
```

## Option 2: Use MongoDB Atlas (Cloud - Free Tier)

1. **Sign up for MongoDB Atlas:**
   - Go to https://www.mongodb.com/cloud/atlas/register
   - Create a free account (M0 Free Tier)

2. **Create a Cluster:**
   - Choose a cloud provider (AWS, Google Cloud, Azure)
   - Select a region closest to you
   - Choose M0 (Free) tier

3. **Set up Database Access:**
   - Go to "Database Access"
   - Create a database user (username/password)
   - Save the credentials

4. **Set up Network Access:**
   - Go to "Network Access"
   - Add IP Address: `0.0.0.0/0` (for development)
   - Or add your specific IP address

5. **Get Connection String:**
   - Go to "Database" → "Connect"
   - Choose "Connect your application"
   - Copy the connection string
   - Replace `<password>` with your database user password
   - Example: `mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/saran?retryWrites=true&w=majority`

6. **Update .env file:**
   ```bash
   cd backend
   # Edit .env file
   MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/saran?retryWrites=true&w=majority
   ```

## Option 3: Use Docker (Alternative)

```bash
# Pull MongoDB image
docker pull mongo:latest

# Run MongoDB container
docker run -d \
  --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  mongo:latest

# Connection string:
# mongodb://admin:password@localhost:27017/saran?authSource=admin
```

## Quick Fix for Now

If you just want to test the server without MongoDB:

1. Create `.env` file in `backend/` directory:
   ```bash
   cd backend
   touch .env
   ```

2. Add MongoDB URI (use MongoDB Atlas for quickest setup):
   ```env
   MONGODB_URI=mongodb://localhost:27017/saran
   NODE_ENV=development
   JWT_SECRET=your-secret-key-change-in-production
   PORT=3000
   ```

3. **Important:** The server will still crash if MongoDB isn't running. You need to:
   - Install MongoDB locally (Option 1), OR
   - Use MongoDB Atlas (Option 2), OR
   - Use Docker (Option 3)

## Verify Connection

After setting up MongoDB, restart your server:
```bash
npm run dev
```

You should see:
```
✅ MongoDB Connected: localhost (or cluster hostname)
🚀 Server running in development mode on port 3000
```

## Troubleshooting

### "connect ECONNREFUSED 127.0.0.1:27017"
- MongoDB is not running
- Start MongoDB: `brew services start mongodb-community` (macOS)
- Or check if MongoDB service is running

### "Authentication failed"
- Check your username/password in connection string
- Verify database user exists in MongoDB Atlas

### "Network timeout"
- Check your IP is whitelisted in MongoDB Atlas
- Or use `0.0.0.0/0` for development (not recommended for production)
