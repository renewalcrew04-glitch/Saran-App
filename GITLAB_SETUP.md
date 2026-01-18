# GitLab Setup Guide for SARAN Project

This guide will help you push your code to GitLab and set up CI/CD.

## Prerequisites

- GitLab account (create one at https://gitlab.com if you don't have one)
- Git installed on your machine
- Your project ready to commit

## Step 1: Create GitLab Repository

1. **Go to GitLab:**
   - Visit https://gitlab.com
   - Log in or create an account

2. **Create New Project:**
   - Click the "+" icon (top right) → "New project/repository"
   - Choose "Create blank project"
   - Fill in:
     - **Project name**: `saran-app` (or your preferred name)
     - **Visibility**: Private (recommended) or Public
     - **Initialize repository with a README**: ❌ Uncheck (we already have files)
   - Click "Create project"

3. **Copy Repository URL:**
   - After creation, GitLab will show you the repository URL
   - It will look like: `https://gitlab.com/your-username/saran-app.git`
   - Copy this URL

## Step 2: Configure Git (if not already done)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Step 3: Add GitLab Remote

In your project directory:

```bash
cd /Users/mano/Downloads/SARAN

# Check if remote already exists
git remote -v

# If no remote exists, add GitLab remote
git remote add origin https://gitlab.com/your-username/saran-app.git

# If remote exists but points to wrong URL, update it:
# git remote set-url origin https://gitlab.com/your-username/saran-app.git
```

## Step 4: Stage and Commit Files

```bash
# Add all new files (backend, flutter_app, etc.)
git add backend/
git add flutter_app/
git add MIGRATION_GUIDE.md
git add README.md
git add .gitignore

# Commit the changes
git commit -m "Initial commit: Migrate to Flutter + Node.js backend with MongoDB and AWS"
```

## Step 5: Push to GitLab

```bash
# Push to GitLab (first time)
git push -u origin master

# Or if your default branch is 'main':
git push -u origin main
```

## Step 6: Configure GitLab CI/CD Variables

1. **Go to GitLab Project:**
   - Navigate to your project on GitLab
   - Go to **Settings** → **CI/CD** → **Variables** (expand "Variables" section)

2. **Add Required Variables:**
   Click "Add variable" for each:

   - **MONGODB_URI**
     - Key: `MONGODB_URI`
     - Value: Your MongoDB Atlas connection string
     - Type: Variable
     - Protected: ✅ (for production)
     - Masked: ✅ (hides in logs)
     - Environment scope: All

   - **AWS_ACCESS_KEY_ID**
     - Key: `AWS_ACCESS_KEY_ID`
     - Value: Your AWS access key ID
     - Type: Variable
     - Protected: ✅
     - Masked: ✅

   - **AWS_SECRET_ACCESS_KEY**
     - Key: `AWS_SECRET_ACCESS_KEY`
     - Value: Your AWS secret access key
     - Type: Variable
     - Protected: ✅
     - Masked: ✅

   - **AWS_REGION**
     - Key: `AWS_REGION`
     - Value: `ap-south-1`
     - Type: Variable
     - Protected: ❌
     - Masked: ❌

   - **JWT_SECRET** (optional, for production)
     - Key: `JWT_SECRET`
     - Value: Your JWT secret
     - Type: Variable
     - Protected: ✅
     - Masked: ✅

## Step 7: Test CI/CD Pipeline

1. **Make a small change:**
   ```bash
   # Make a small change to trigger pipeline
   echo "# Test" >> README.md
   git add README.md
   git commit -m "Test CI/CD pipeline"
   git push
   ```

2. **Check Pipeline:**
   - Go to GitLab → Your Project → **CI/CD** → **Pipelines**
   - You should see a pipeline running
   - Click on it to see the stages (test, build, deploy)

## Step 8: Branch Strategy

For development workflow:

```bash
# Create development branch
git checkout -b develop
git push -u origin develop

# Create feature branches
git checkout -b feature/user-authentication
# ... make changes ...
git commit -m "Add user authentication"
git push -u origin feature/user-authentication

# Create merge request in GitLab
```

## Troubleshooting

### "Permission denied" error:
- Check your GitLab credentials
- Use Personal Access Token instead of password:
  - GitLab → Settings → Access Tokens
  - Create token with `write_repository` scope
  - Use token as password when pushing

### "Remote origin already exists":
```bash
# Remove existing remote
git remote remove origin

# Add new remote
git remote add origin https://gitlab.com/your-username/saran-app.git
```

### CI/CD Pipeline fails:
- Check GitLab CI/CD → Pipelines → Failed job → View logs
- Verify all CI/CD variables are set correctly
- Check `.gitlab-ci.yml` syntax

## Next Steps

1. ✅ Code pushed to GitLab
2. ✅ CI/CD variables configured
3. ⚪ Implement remaining backend controllers
4. ⚪ Build Flutter app features
5. ⚪ Set up deployment to AWS (EC2/Elastic Beanstalk)

## Useful GitLab Features

- **Issues**: Track bugs and features
- **Merge Requests**: Code review workflow
- **CI/CD**: Automated testing and deployment
- **Wiki**: Document your project
- **Snippets**: Share code snippets

## Security Best Practices

1. ✅ Never commit `.env` files
2. ✅ Use GitLab CI/CD variables for secrets
3. ✅ Enable "Masked" for sensitive variables
4. ✅ Use "Protected" variables for production
5. ✅ Rotate access keys regularly
6. ✅ Use branch protection rules
