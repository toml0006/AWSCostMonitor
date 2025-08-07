# GitHub Pages Setup Instructions

To enable GitHub Pages deployment for this repository, follow these steps:

## 1. Enable GitHub Pages

1. Go to your repository settings: https://github.com/toml0006/AWSCostMonitor/settings/pages
2. Under "Source", select **GitHub Actions**
3. Click Save

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