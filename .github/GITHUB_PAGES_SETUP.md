# GitHub Pages Setup Instructions

To enable GitHub Pages deployment for this repository, follow these steps:

## IMPORTANT: First Time Setup

### 1. Enable GitHub Pages

1. Go to your repository settings: https://github.com/toml0006/AWSCostMonitor/settings/pages
2. Under "Build and deployment", find "Source"
3. Select **GitHub Actions** from the dropdown
4. Click Save

### 2. Remove Environment Protection (if exists)

If you see "environment protection rules" errors:

1. Go to Settings → Environments: https://github.com/toml0006/AWSCostMonitor/settings/environments
2. If "github-pages" environment exists, click on it
3. Either:
   - Delete the environment entirely (click trash icon), OR
   - Under "Deployment branches", ensure "main" is allowed, OR
   - Remove all protection rules

## 2. Configure Environment (Optional)

If you want to add deployment protection:

1. Go to Settings → Environments
2. Click on "github-pages" environment (created automatically)
3. Configure protection rules as needed:
   - Add required reviewers
   - Restrict which branches can deploy
   - Add deployment branch policy

## 3. Verify Deployment

After pushing to main, the website will be available at:
https://toml0006.github.io/AWSCostMonitor/

## Troubleshooting

If you see "Branch 'main' is not allowed to deploy to github-pages due to environment protection rules":
- Either remove environment protection rules
- Or add 'main' branch to the allowed deployment branches in the environment settings