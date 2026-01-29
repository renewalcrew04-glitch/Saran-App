import fs from "fs";
import multer from "multer";
import path from "path";

const uploadDir = path.join(process.cwd(), "uploads");

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
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

     const host = req.get("host");

// If request comes from emulator, host may be "10.0.2.2:3000" already.
// If it comes as "localhost:3000", Android cannot load it.
let baseUrl = `${req.protocol}://${host}`;

if (host.includes("localhost")) {
  baseUrl = `http://10.0.2.2:3000`;
}

const fileUrl = `${baseUrl}/uploads/${req.file.filename}`;

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
