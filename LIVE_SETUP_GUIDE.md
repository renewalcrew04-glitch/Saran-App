# SARAN – Live setup guide

The Flutter app is configured to use the **live API** at `http://13.233.133.213:3000/api/` (no localhost).

---

## 1. Backend (run on your Mac, connect to live MongoDB)

### One-time: set MongoDB (Atlas)

1. Go to [MongoDB Atlas](https://cloud.mongodb.com) → your project → **Database** → **Connect** → **Drivers**.
2. Copy the Node.js connection string (e.g. `mongodb+srv://user:pass@cluster0.xxxxx.mongodb.net/...`).
3. In the backend folder, create or edit `.env`:

```bash
cd /Users/mano/Downloads/Saran_one/SARAN/backend
```

Create `.env` with (use your real values):

```env
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb+srv://YOUR_USER:YOUR_PASSWORD@YOUR_CLUSTER.mongodb.net/saran?retryWrites=true&w=majority
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

Replace `YOUR_USER`, `YOUR_PASSWORD`, and `YOUR_CLUSTER` with your Atlas details.

### Start the backend

```bash
cd /Users/mano/Downloads/Saran_one/SARAN/backend
npm install
npm run dev
```

You should see:

- `Server running on http://0.0.0.0:3000`
- `MongoDB connected` (or similar)

Leave this terminal open. The app will call this server if it’s on the same network, **or** you run the backend on the live server (see section 3).

---

## 2. Flutter app (uses live API)

The app already points to `http://13.233.133.213:3000/api/`. No code change needed.

### Run on iOS simulator

```bash
cd /Users/mano/Downloads/Saran_one/SARAN/flutter_app
flutter pub get
flutter run
```

Pick the iOS device/simulator when asked.

### Run on Android emulator/device

```bash
cd /Users/mano/Downloads/Saran_one/SARAN/flutter_app
flutter pub get
flutter run
```

### Build release (e.g. for App Store / Play Store)

**iOS:**

```bash
cd /Users/mano/Downloads/Saran_one/SARAN/flutter_app
flutter build ios
```

**Android:**

```bash
cd /Users/mano/Downloads/Saran_one/SARAN/flutter_app
flutter build appbundle
```

---

## 3. Run backend on the live server (13.233.133.213)

If you want the API to run on the server (so the app and others hit it at `http://13.233.133.213:3000`):

### Step A: Upload backend from your Mac to the server

From your **Mac** (in a new terminal, not on the server):

```bash
cd /Users/mano/Downloads/Saran_one/SARAN
scp -r backend ubuntu@13.233.133.213:~/
```

(Use your server’s real IP if different from 13.233.133.213; use your SSH key if you have one.)

This creates `/home/ubuntu/backend` on the server with the full backend folder (including `package.json`, `src/`, etc.).

### Step B: SSH into the server

```bash
ssh ubuntu@13.233.133.213
```

(Replace with your server user and IP if different.)

### Step C: On the server – install Node (if needed) and run backend

```bash
# If Node not installed (Ubuntu/Debian):
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Go to the backend folder (real path after upload):
cd ~/backend
npm install
```

Create `.env` on the server with the same `MONGODB_URI` (Atlas) and `JWT_SECRET`.

### Run with PM2 (keeps it running)

```bash
sudo npm install -g pm2
pm2 start src/server.js --name saran-api
pm2 save
pm2 startup
```

Then the live API is at `http://13.233.133.213:3000` and the Flutter app will use it.

---

## Quick reference

| Task              | Command |
|-------------------|--------|
| Backend (dev)     | `cd backend && npm run dev` |
| Flutter run       | `cd flutter_app && flutter run` |
| Flutter deps      | `cd flutter_app && flutter pub get` |
| Backend deps      | `cd backend && npm install` |

---

## Troubleshooting

- **“MongoDB connection error”**  
  Fix `MONGODB_URI` in backend `.env` (use real Atlas string, not `cluster0.xxxxx.mongodb.net`).

- **“Failed to send SOS” / API errors**  
  Ensure the backend is running (local or on 13.233.133.213) and the app’s base URL in `flutter_app/lib/config/api_config_constants.dart` is `http://13.233.133.213:3000/api/`.

- **App can’t reach API from device**  
  If the backend runs on your Mac, the phone must be on the same Wi‑Fi or you must run the backend on the live server (section 3).
