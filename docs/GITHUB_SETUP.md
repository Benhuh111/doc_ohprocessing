# GitHub Token Setup Guide for CodePipeline

## Step 1: Create GitHub Personal Access Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   URL: https://github.com/settings/tokens

2. Click "Generate new token (classic)"

3. Set the following:
   - Note: "AWS CodePipeline for Doc_Ohpp"
   - Expiration: 90 days (or as needed)
   - Select scopes:
     ✓ repo (Full control of private repositories)
     ✓ admin:repo_hook (Full control of repository hooks)

4. Click "Generate token"

5. IMPORTANT: Copy the token immediately (you won't see it again)

## Step 2: Deploy the Pipeline

Run this command in PowerShell (replace with your values):

```powershell
.\deploy-codepipeline.ps1 `
  -GitHubOwner "YourGitHubUsername" `
  -GitHubRepo "Doc_Ohpp" `
  -GitHubToken "ghp_your_token_here" `
  -GitHubBranch "main" `
  -EC2KeyPair "your-key-pair-name"
```

## Step 3: Verify Deployment

1. Check AWS Console → CodePipeline
2. Push code to GitHub
3. Watch pipeline execute automatically

## Troubleshooting

- If token is invalid: Check scopes and regenerate
- If deployment fails: Check AWS permissions
- If EC2 key pair not found: Create one in EC2 console
