import nodemailer from 'nodemailer';

let transporter = null;

const getTransporter = () => {
  if (transporter) return transporter;

  const host = process.env.EMAIL_HOST;
  const user = process.env.EMAIL_USER;
  const pass = process.env.EMAIL_PASS;

  if (!host || !user || !pass) {
    return null; // dev mode: log to console
  }

  transporter = nodemailer.createTransport({
    host,
    port: parseInt(process.env.EMAIL_PORT || '587'),
    secure: process.env.EMAIL_SECURE === 'true',
    auth: { user, pass },
  });

  return transporter;
};

export const sendOtpEmail = async (email, otp) => {
  const transport = getTransporter();

  if (!transport) {
    // Local dev fallback — print OTP to console
    console.log(`\n📧 OTP for ${email}: ${otp}\n`);
    return;
  }

  try {
    await transport.sendMail({
      from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
      to: email,
      subject: 'Your SARAN verification code',
      html: `
        <div style="font-family:sans-serif;max-width:480px;margin:auto;padding:32px;background:#fff;border-radius:12px;">
          <h2 style="color:#d63384;margin-bottom:8px;">SARAN</h2>
          <p style="font-size:15px;color:#333;">Your email verification code is:</p>
          <div style="font-size:40px;font-weight:700;letter-spacing:12px;color:#d63384;margin:24px 0;">${otp}</div>
          <p style="font-size:13px;color:#888;">This code expires in 10 minutes. Do not share it with anyone.</p>
        </div>
      `,
    });
  } catch (err) {
    // Reset cached transporter so next attempt retries with fresh connection
    transporter = null;

    // Log the real error server-side for debugging
    console.error('Email send failed:', err.message);

    // Throw a clean, user-safe error (no raw SMTP details)
    const error = new Error('Failed to send verification email. Please check your email address and try again.');
    error.statusCode = 503;
    throw error;
  }
};
