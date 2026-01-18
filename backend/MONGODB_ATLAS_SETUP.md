# MongoDB Atlas Setup Guide (Google Login)

If you use Google to log into MongoDB Atlas, you still need to create a **Database User** separately for your application to connect.

## Step-by-Step: Create Database User

### 1. Log into MongoDB Atlas
- Go to https://cloud.mongodb.com/
- Log in with your Google account

### 2. Navigate to Database Access
- Click on **"Database Access"** in the left sidebar
- Or go to: Security → Database Access

### 3. Create a New Database User
- Click **"+ ADD NEW DATABASE USER"** button
- Choose authentication method: **"Password"** (not Atlas Login)

### 4. Set Up Database User Credentials
- **Username**: Create a username (e.g., `saran_app_user` or `admin`)
- **Password**: 
  - Option A: Click **"Autogenerate Secure Password"** (recommended)
    - Copy the generated password immediately - you won't see it again!
  - Option B: Create your own password
  
- **User Privileges**: Select **"Atlas admin"** (for development) or **"Read and write to any database"**
- Click **"Add User"**

### 5. Get Your Connection String

1. Go to **"Database"** in the left sidebar
2. Click **"Connect"** button on your cluster
3. Choose **"Connect your application"**
4. Select Driver: **"Node.js"** and Version: **"5.5 or later"**
5. Copy the connection string

**Example connection string:**
```
mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

### 6. Update Your .env File

Replace the placeholders in the connection string:
- `<username>` → Your database user username (e.g., `saran_app_user`)
- `<password>` → Your database user password (the one you created/generated in step 4)

**Final connection string should look like:**
```
mongodb+srv://saran_app_user:MySecurePassword123@cluster0.abc123.mongodb.net/saran?retryWrites=true&w=majority
```

### 7. Set Network Access (Important!)

1. Go to **"Network Access"** in the left sidebar
2. Click **"+ ADD IP ADDRESS"**
3. For development, add:
   - **"ALLOW ACCESS FROM ANYWHERE"** → `0.0.0.0/0`
   - OR add your specific IP address
4. Click **"Confirm"**

⚠️ **Note**: `0.0.0.0/0` allows access from anywhere (only for development). For production, use specific IP addresses.

## Example .env Configuration

```env
# MongoDB Atlas Connection String
# Format: mongodb+srv://DATABASE_USERNAME:DATABASE_PASSWORD@cluster0.xxxxx.mongodb.net/database-name?retryWrites=true&w=majority
MONGODB_URI=mongodb+srv://saran_app_user:MySecurePassword123@cluster0.abc123.mongodb.net/saran?retryWrites=true&w=majority
```

## Summary

- **MongoDB Atlas Google Login** = Your account login (for accessing the website)
- **Database User** = Separate credentials created in "Database Access" (for app connections)

**You need to create a Database User** even though you log in with Google!

## Troubleshooting

### "Authentication failed"
- Make sure you're using the **Database User** password, not your Google account password
- Check username and password are correct in connection string
- Ensure special characters in password are URL-encoded (e.g., `@` becomes `%40`)

### "Connection timeout"
- Check Network Access settings - your IP must be whitelisted
- Use `0.0.0.0/0` for development (not recommended for production)

### "Password has special characters"
If your password has special characters like `@`, `#`, `%`, etc., you need to URL-encode them:
- `@` → `%40`
- `#` → `%23`
- `%` → `%25`
- `&` → `%26`
- etc.

Or regenerate a password without special characters.
