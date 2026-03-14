import fs from "fs";
import multer from "multer";
import multerS3 from "multer-s3";
import path from "path";
import { s3, S3_BUCKET } from "../config/aws.js";

const uploadDir = path.join(process.cwd(), "uploads");

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const hasAwsConfig = !!(
  process.env.AWS_ACCESS_KEY_ID &&
  process.env.AWS_SECRET_ACCESS_KEY &&
  process.env.AWS_S3_BUCKET_NAME
);

// S3 storage - permanent; survives deploys/restarts
const s3Storage = multerS3({
  s3,
  bucket: S3_BUCKET,
  acl: "public-read",
  contentType: multerS3.AUTO_CONTENT_TYPE,
  key: (_, file, cb) => {
    const ext = path.extname(file.originalname) || ".jpg";
    const name = `uploads/${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
    cb(null, name);
  },
});

// Disk storage - fallback for local dev when AWS not configured
const diskStorage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) => {
    const ext = path.extname(file.originalname) || ".jpg";
    const name = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
    cb(null, name);
  },
});

const upload = multer({
  storage: hasAwsConfig ? s3Storage : diskStorage,
});

export const uploadSingle = [
  upload.single("file"),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "No file uploaded",
        });
      }

      let fileUrl;

      if (hasAwsConfig) {
        // S3: req.file.location is the permanent public URL
        fileUrl = req.file.location;
      } else {
        // Disk: build URL from server host (local dev only)
        const host = req.get("host");
        let baseUrl = `${req.protocol}://${host}`;
        if (host?.includes("localhost")) {
          baseUrl = "http://10.0.2.2:3000";
        }
        fileUrl = `${baseUrl}/uploads/${req.file.filename}`;
      }

      return res.json({
        success: true,
        message: "Uploaded successfully",
        url: fileUrl,
      });
    } catch (e) {
      return res.status(500).json({
        success: false,
        message: "Upload failed",
      });
    }
  },
];
