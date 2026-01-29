#!/bin/bash

# SARAN Backend EC2 Setup Script
# Run this script on your EC2 instance to set up the environment

set -e

echo "🚀 SARAN Backend EC2 Setup"
echo "=========================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
echo -e "${YELLOW}📦 Installing Node.js 18...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo -e "${GREEN}✅ Node.js already installed${NC}"
fi

NODE_VERSION=$(node -v)
echo -e "${GREEN}✅ Node.js version: $NODE_VERSION${NC}"

# Install PM2
echo -e "${YELLOW}📦 Installing PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
else
    echo -e "${GREEN}✅ PM2 already installed${NC}"
fi

PM2_VERSION=$(pm2 -v)
echo -e "${GREEN}✅ PM2 version: $PM2_VERSION${NC}"

# Install Git
echo -e "${YELLOW}📦 Installing Git...${NC}"
if ! command -v git &> /dev/null; then
    sudo apt install -y git
else
    echo -e "${GREEN}✅ Git already installed${NC}"
fi

# Install build essentials (for native modules)
echo -e "${YELLOW}📦 Installing build essentials...${NC}"
sudo apt install -y build-essential

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Clone your repository: git clone <your-repo-url> SARAN"
echo "2. cd SARAN/backend"
echo "3. npm install --production"
echo "4. cp .env.example .env"
echo "5. nano .env  # Edit with your values"
echo "6. ./deploy.sh"
