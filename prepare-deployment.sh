#!/bin/bash

# SARAN Deployment Preparation Script
# This script helps you prepare all values needed for deployment

set -e

echo "🚀 SARAN Deployment Preparation"
echo "==============================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}This script will help you prepare values for deployment.${NC}"
echo ""

# Generate JWT Secret
echo -e "${YELLOW}📝 Generating JWT Secret...${NC}"
JWT_SECRET=$(openssl rand -base64 32)
echo -e "${GREEN}✅ JWT Secret generated${NC}"
echo ""

# Display values
echo "════════════════════════════════════════════════════════════"
echo "📋 VALUES FOR GITLAB CI/CD VARIABLES"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Copy these values to GitLab → Settings → CI/CD → Variables:"
echo ""
echo "1. MONGODB_URI"
echo "   Value: <Your MongoDB Atlas connection string>"
echo "   Format: mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/saran?retryWrites=true&w=majority"
echo ""
echo "2. JWT_SECRET"
echo "   Value: ${JWT_SECRET}"
echo "   (Copy this value - it's unique!)"
echo ""
echo "3. AWS_ACCESS_KEY_ID"
echo "   Value: <Your AWS access key ID>"
echo ""
echo "4. AWS_SECRET_ACCESS_KEY"
echo "   Value: <Your AWS secret access key>"
echo ""
echo "5. AWS_REGION"
echo "   Value: ap-south-1"
echo ""
echo "6. AWS_S3_BUCKET_NAME"
echo "   Value: saran-media-storage"
echo ""
echo "7. CORS_ORIGIN"
echo "   Value: *"
echo ""
echo "8. NODE_ENV"
echo "   Value: production"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Save JWT secret to file
echo "$JWT_SECRET" > .jwt_secret.txt
echo -e "${GREEN}✅ JWT Secret saved to .jwt_secret.txt${NC}"
echo -e "${YELLOW}⚠️  Keep this file secure! Delete it after deployment.${NC}"
echo ""

# Create .env template
echo -e "${YELLOW}📝 Creating .env template...${NC}"
cat > backend/.env.template << EOF
# SARAN Backend Environment Variables
# Copy this to .env and fill in your values

NODE_ENV=production
PORT=3000

# MongoDB Configuration
MONGODB_URI=your-mongodb-atlas-connection-string

# JWT Configuration
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRES_IN=7d

# AWS Configuration
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
AWS_S3_BUCKET_NAME=saran-media-storage

# CORS Configuration
CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

echo -e "${GREEN}✅ .env template created at backend/.env.template${NC}"
echo ""

# Display next steps
echo "════════════════════════════════════════════════════════════"
echo "📋 NEXT STEPS"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1. Set GitLab Variables:"
echo "   - Go to GitLab → Settings → CI/CD → Variables"
echo "   - Add all 8 variables listed above"
echo ""
echo "2. Deploy Backend:"
echo "   - Follow DEPLOY_NOW.md for step-by-step instructions"
echo "   - Or use: ./backend/setup-ec2.sh on your EC2 instance"
echo ""
echo "3. Test Deployment:"
echo "   - Run: ./backend/test-deployment.sh"
echo ""
echo "4. Update Flutter App:"
echo "   - Edit flutter_app/lib/config/api_config.dart line 17"
echo "   - Update with your production API URL"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ Preparation complete!${NC}"
echo ""
echo "📚 Documentation:"
echo "   - DEPLOY_NOW.md - Step-by-step deployment guide"
echo "   - QUICK_DEPLOY_CHECKLIST.md - Deployment checklist"
echo "   - GITLAB_VARIABLES.md - GitLab variables guide"
echo ""
