# MongoDB Atlas + AWS Integration Guide

This guide explains how to connect MongoDB Atlas with AWS services for your SARAN backend.

## Overview

MongoDB Atlas can integrate with AWS in several ways:

1. **MongoDB Atlas on AWS Infrastructure** - Your cluster may already be running on AWS
2. **AWS S3 Integration** - Store media files in S3 (already configured in your backend)
3. **VPC Peering** - Connect Atlas cluster to AWS VPC
4. **AWS Lambda Integration** - Serverless functions accessing MongoDB
5. **AWS Backup/Snapshot** - Backup MongoDB to AWS S3

## Current Setup

Your backend already uses:
- **MongoDB Atlas** - Database (cluster0.fhi5b.mongodb.net)
- **AWS S3** - Media storage (configured in `src/config/aws.js`)

## 1. MongoDB Atlas on AWS Infrastructure

### Check Your Cluster Provider

1. Go to MongoDB Atlas → Database → Your Cluster
2. Click on your cluster name
3. Check the **Cloud Provider** - it should show **"AWS"** if running on AWS

**If your cluster is on AWS:**
- ✅ You're already using AWS infrastructure
- Your data is stored on AWS servers
- No additional connection needed for basic usage

## 2. AWS S3 Integration (Already Configured)

Your backend already has S3 integration set up for media storage.

### How It Works:

1. **Backend generates presigned URLs** (`src/config/aws.js`)
2. **Flutter app uploads media directly to S3** using presigned URLs
3. **Backend stores S3 URLs in MongoDB** (in Post, SFrame, etc. models)

### Setup Steps:

#### Step 1: Create AWS S3 Bucket

1. Go to [AWS Console](https://console.aws.amazon.com/)
2. Navigate to **S3** service
3. Click **"Create bucket"**
4. Configure:
   - **Bucket name**: `saran-media-storage` (or your preferred name)
   - **Region**: Choose closest to your MongoDB Atlas region
   - **Block Public Access**: Enable (we'll use presigned URLs)
   - Click **"Create bucket"**

#### Step 2: Create IAM User for S3 Access

1. Go to **IAM** service in AWS Console
2. Click **"Users"** → **"Create user"**
3. Enter username: `saran-s3-user`
4. Select **"Programmatic access"** (for API keys)
5. Click **"Next: Permissions"**
6. Click **"Attach policies directly"**
7. Search and select: **"AmazonS3FullAccess"** (or create a custom policy)
8. Click **"Next"** → **"Create user"**
9. **Important**: Copy the **Access Key ID** and **Secret Access Key** immediately

#### Step 3: Configure CORS (for Flutter app)

1. Go to your S3 bucket → **"Permissions"** tab
2. Scroll to **"Cross-origin resource sharing (CORS)"**
3. Click **"Edit"** and add:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"],
        "MaxAgeSeconds": 3000
    }
]
```

4. Click **"Save changes"**

#### Step 4: Update Your `.env` File

Add your AWS credentials to `backend/.env`:

```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key-id-here
AWS_SECRET_ACCESS_KEY=your-secret-access-key-here
AWS_S3_BUCKET_NAME=saran-media-storage
```

**Important**: Replace with your actual AWS credentials from Step 2.

## 3. VPC Peering (Optional - For Production)

If you deploy your backend to AWS EC2/ECS and want private network connection:

### Benefits:
- ✅ Private network connection (not over internet)
- ✅ Better security
- ✅ Lower latency

### Setup Steps:

1. **In MongoDB Atlas:**
   - Go to **Network Access** → **"Add IP Address"**
   - OR go to **Network Access** → **"Peering"** tab
   - Click **"Add Peering Connection"**
   - Select **AWS** as provider
   - Follow the setup wizard

2. **In AWS:**
   - Create VPC Peering Connection
   - Configure route tables
   - Update security groups

**Note**: VPC Peering is mainly needed if your backend runs on AWS EC2/ECS. For local development or other hosting, IP whitelisting is sufficient.

## 4. Backup MongoDB to AWS S3 (Optional)

### Using MongoDB Atlas Backup:

1. Go to MongoDB Atlas → **Backup** tab
2. Enable **Cloud Backup** (if not enabled)
3. MongoDB Atlas automatically backs up to cloud storage
4. Can export/restore from backups

### Manual Backup Script:

You can create a script to backup MongoDB to S3:

```javascript
// backup-to-s3.js
import { exec } from 'child_process';
import { uploadToS3 } from './src/config/aws.js';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function backupMongoDBToS3() {
  const timestamp = new Date().toISOString().replace(/:/g, '-');
  const backupFile = `mongodb-backup-${timestamp}.gz`;
  
  // Export from MongoDB Atlas (you'd need mongodump)
  // Then upload to S3
  // Implementation depends on your setup
}
```

## 5. AWS Lambda Integration (Advanced)

If you want to use AWS Lambda functions with MongoDB:

### Setup:

1. **Create Lambda Function:**
   - Go to AWS Lambda → **"Create function"**
   - Choose runtime (Node.js 18.x)

2. **Connect to MongoDB Atlas:**
   - Add MongoDB connection in Lambda
   - Use environment variables for connection string
   - Or use MongoDB Atlas Data API

3. **Configure VPC (if needed):**
   - Attach Lambda to same VPC as MongoDB (if using VPC Peering)

## Current Architecture

```
┌─────────────┐
│  Flutter    │
│    App      │
└──────┬──────┘
       │ HTTP/HTTPS
       ▼
┌─────────────────┐
│  Backend API    │ ← Node.js/Express
│  (Your Server)  │
└────┬────────┬───┘
     │        │
     ▼        ▼
┌─────────┐ ┌─────────┐
│ MongoDB │ │  AWS S3 │
│  Atlas  │ │ (Media) │
└─────────┘ └─────────┘
```

## Testing S3 Connection

After setting up AWS credentials, test the connection:

```bash
cd backend
node -e "
import { s3, S3_BUCKET } from './src/config/aws.js';
console.log('S3 Bucket:', S3_BUCKET);
console.log('S3 configured successfully!');
"
```

## Troubleshooting

### "Access Denied" errors:
- Check IAM user permissions
- Verify bucket name in `.env`
- Check AWS region matches bucket region

### "Bucket not found":
- Verify bucket name in `.env`
- Check bucket exists in AWS Console
- Verify AWS credentials are correct

### Connection timeouts:
- Check AWS region in `.env` matches bucket region
- Verify network access (CORS configured)

## Next Steps

1. ✅ **Set up AWS S3 bucket** (for media storage)
2. ✅ **Create IAM user** (for S3 access)
3. ✅ **Update `.env`** with AWS credentials
4. ✅ **Test S3 upload** from your Flutter app
5. ⚪ **Configure VPC Peering** (if deploying to AWS EC2/ECS)
6. ⚪ **Set up automated backups** (optional)

## Resources

- [MongoDB Atlas on AWS](https://www.mongodb.com/cloud/atlas/aws)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [VPC Peering Guide](https://docs.atlas.mongodb.com/security-vpc-peering/)
- [IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/)
