import AWS from 'aws-sdk';
import dotenv from 'dotenv';
import { S3Client } from '@aws-sdk/client-s3';

dotenv.config();

// Configure AWS
AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

// S3 Configuration (AWS SDK v2 - used by existing helper functions)
export const s3V2 = new AWS.S3({
  signatureVersion: 'v4',
  region: process.env.AWS_REGION || 'us-east-1'
});

export const S3_BUCKET = process.env.AWS_S3_BUCKET_NAME || 'saran-media-storage';

// S3 Configuration (AWS SDK v3 - required by multer-s3 v3)
export const s3V3 = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY
    ? {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      }
    : undefined
});

// Generate presigned URL for upload
export const generatePresignedUploadUrl = (key, contentType, expiresIn = 3600) => {
  return s3V2.getSignedUrl('putObject', {
    Bucket: S3_BUCKET,
    Key: key,
    ContentType: contentType,
    Expires: expiresIn
  });
};

// Generate presigned URL for download/view
export const generatePresignedDownloadUrl = (key, expiresIn = 3600) => {
  return s3V2.getSignedUrl('getObject', {
    Bucket: S3_BUCKET,
    Key: key,
    Expires: expiresIn
  });
};

// Upload file to S3
export const uploadToS3 = (buffer, key, contentType) => {
  return new Promise((resolve, reject) => {
    const params = {
      Bucket: S3_BUCKET,
      Key: key,
      Body: buffer,
      ContentType: contentType
    };

    s3V2.upload(params, (err, data) => {
      if (err) {
        reject(err);
      } else {
        resolve(data.Location);
      }
    });
  });
};

// Delete file from S3
export const deleteFromS3 = (key) => {
  return new Promise((resolve, reject) => {
    const params = {
      Bucket: S3_BUCKET,
      Key: key
    };

    s3V2.deleteObject(params, (err, data) => {
      if (err) {
        reject(err);
      } else {
        resolve(data);
      }
    });
  });
};
