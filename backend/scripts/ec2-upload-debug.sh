#!/bin/bash
# Run this ON THE EC2 SERVER (after ssh) to see why /api/upload returns 404.
# Usage: ssh ubuntu@YOUR_EC2_IP, then: cd backend && bash scripts/ec2-upload-debug.sh

set -e
echo "=== 1. Which directory is PM2 actually using? ==="
pm2 show saran-api 2>/dev/null | grep -E "exec cwd|script path" || echo "PM2 app 'saran-api' not found"

echo ""
echo "=== 2. Contents of upload.routes.js IN THAT DIRECTORY ==="
PM2_CWD=$(pm2 show saran-api 2>/dev/null | grep "exec cwd" | sed 's/.*: //' | tr -d ' ')
if [ -n "$PM2_CWD" ] && [ -f "$PM2_CWD/src/routes/upload.routes.js" ]; then
  cat "$PM2_CWD/src/routes/upload.routes.js"
else
  echo "Checking current dir: $(pwd)"
  if [ -f "src/routes/upload.routes.js" ]; then
    cat src/routes/upload.routes.js
  else
    echo "upload.routes.js not found in current dir"
  fi
fi

echo ""
echo "=== 3. Does server.js have the upload/check route? ==="
if [ -n "$PM2_CWD" ]; then
  grep -n "upload/check\|upload.*uploadRoutes" "$PM2_CWD/src/server.js" 2>/dev/null || true
else
  grep -n "upload/check\|upload.*uploadRoutes" src/server.js 2>/dev/null || true
fi

echo ""
echo "=== 4. What is listening on port 3000? ==="
sudo lsof -i :3000 2>/dev/null || true

echo ""
echo "=== 5. Last 5 lines of PM2 logs ==="
pm2 logs saran-api --lines 5 --nostream 2>/dev/null || true
