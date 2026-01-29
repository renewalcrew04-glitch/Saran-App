#!/bin/bash

# SARAN Backend Deployment Script
# This script helps deploy the backend to EC2

set -e

echo "🚀 SARAN Backend Deployment Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ Error: .env file not found!${NC}"
    echo "Please create .env file from .env.example"
    exit 1
fi

echo -e "${GREEN}✅ .env file found${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Error: Node.js not found!${NC}"
    echo "Please install Node.js 18+"
    exit 1
fi

NODE_VERSION=$(node -v)
echo -e "${GREEN}✅ Node.js version: $NODE_VERSION${NC}"

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
npm install --production

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}⚠️  PM2 not found. Installing...${NC}"
    sudo npm install -g pm2
fi

echo -e "${GREEN}✅ PM2 installed${NC}"

# Start/restart application
echo -e "${YELLOW}🔄 Starting application...${NC}"

if pm2 list | grep -q "saran-api"; then
    echo -e "${YELLOW}⚠️  Application already running. Restarting...${NC}"
    pm2 restart saran-api
else
    echo -e "${GREEN}✅ Starting new instance...${NC}"
    pm2 start src/server.js --name saran-api
fi

# Save PM2 configuration
pm2 save

echo -e "${GREEN}✅ Application started!${NC}"
echo ""
echo "📊 Application Status:"
pm2 status

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Useful commands:"
echo "  pm2 logs saran-api          # View logs"
echo "  pm2 restart saran-api        # Restart app"
echo "  pm2 stop saran-api           # Stop app"
echo "  pm2 monit                    # Monitor app"
