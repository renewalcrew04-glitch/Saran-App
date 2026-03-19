import { PutObjectCommand } from "@aws-sdk/client-s3";
import fs from "fs";
import multer from "multer";
import path from "path";
import { S3_BUCKET, s3V3 } from "../config/aws.js";

const uploadDir = path.join(process.cwd(), "uploads");

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const hasAwsConfig = !!(
  process.env.AWS_ACCESS_KEY_ID &&
  process.env.AWS_SECRET_ACCESS_KEY &&
  process.env.AWS_S3_BUCKET_NAME
);

// Use memory storage for AWS uploads, disk for local fallback
const storage = hasAwsConfig
  ? multer.memoryStorage()
  : multer.diskStorage({
      destination: (_, __, cb) => cb(null, uploadDir),
      filename: (_, file, cb) => {
        const ext = path.extname(file.originalname) || ".jpg";
        const name = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
        cb(null, name);
      },
    });

const upload = multer({ storage });

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
        const ext = path.extname(req.file.originalname) || ".jpg";
        const key = `uploads/${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;

        await s3V3.send(
          new PutObjectCommand({
            Bucket: S3_BUCKET,
            Key: key,
            Body: req.file.buffer,
            ContentType: req.file.mimetype,
          })
        );

        fileUrl = `https://${S3_BUCKET}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
      } else {
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
      console.error("[Upload] Error:", e?.message ?? e);
      return res.status(500).json({
        success: false,
        message:
          process.env.NODE_ENV === "production"
            ? "Upload failed"
            : `Upload failed: ${e?.message ?? e}`,
      });
    }
  },
];