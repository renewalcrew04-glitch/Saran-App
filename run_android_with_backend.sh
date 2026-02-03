#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FLUTTER_DIR="$ROOT_DIR/flutter_app"

if [ ! -d "$BACKEND_DIR/node_modules" ]; then
  echo "Installing backend dependencies..."
  (cd "$BACKEND_DIR" && npm install)
fi

echo "Starting backend..."
(cd "$BACKEND_DIR" && npm run dev) &
BACKEND_PID=$!

cleanup() {
  if kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "Starting Flutter app on Android..."
(cd "$FLUTTER_DIR" && flutter run -d android)
