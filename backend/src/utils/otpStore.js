/**
 * In-memory OTP store with auto-expiry.
 * Map<email → { otp, expiresAt }>
 * OTPs expire after 10 minutes.
 */

const store = new Map();
const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes

export const saveOtp = (email, otp) => {
  store.set(email.toLowerCase(), {
    otp: String(otp),
    expiresAt: Date.now() + OTP_TTL_MS,
  });
};

export const verifyOtp = (email, otp) => {
  const entry = store.get(email.toLowerCase());
  if (!entry) return { valid: false, reason: 'No OTP found for this email' };
  if (Date.now() > entry.expiresAt) {
    store.delete(email.toLowerCase());
    return { valid: false, reason: 'OTP has expired' };
  }
  if (entry.otp !== String(otp)) {
    return { valid: false, reason: 'Incorrect OTP' };
  }
  store.delete(email.toLowerCase());
  return { valid: true };
};

export const generateOtp = () =>
  String(Math.floor(100000 + Math.random() * 900000));
