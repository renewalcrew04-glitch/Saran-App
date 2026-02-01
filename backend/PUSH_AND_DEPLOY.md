# Push backend code & deploy

## 1. Push backend code to Git (from your machine)

From the **SARAN** project root (one level above `backend`):

```bash
cd /Users/mano/Desktop/Saran_one/SARAN

# Stage only backend changes (optional: add flutter_app if you want to push app too)
git add backend/

# Commit
git commit -m "Backend: fix post create URL, user posts route, profile feed"

# Push to your remote (e.g. origin master)
git push origin master
```

If your main branch is `main` instead of `master`:

```bash
git push origin main
```

---

## 2. Deploy on the server (EC2)

After pushing, on your **EC2 server**:

```bash
# SSH into EC2 first, then:
cd SARAN          # or wherever you cloned the repo
git pull origin master   # or main

cd backend
./deploy.sh
```

`deploy.sh` will install deps (if needed), restart the app with PM2, and save the process list.

---

## Quick reference

| Step | Where | Command |
|------|--------|---------|
| Push code | Your Mac (in SARAN folder) | `git add backend/ && git commit -m "..." && git push origin master` |
| Deploy | EC2 (after SSH) | `cd SARAN && git pull && cd backend && ./deploy.sh` |
