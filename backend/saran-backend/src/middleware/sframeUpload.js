import multer from "multer";
import multerS3 from "multer-s3";
import { s3 } from "../utils/s3.js";

export const sframeUpload = multer({
  storage: multerS3({
    s3,
    bucket: "saran-sframes",
    acl: "public-read",
    key: (_, file, cb) => {
      cb(null, `sframes/${Date.now()}-${file.originalname}`);
    },
  }),
});
