# Troubleshooting Guide

Common issues and their solutions.

## No AWS Profiles Found

**Problem**: App shows "No profiles found" when launched.

**Solutions**:
1. **Check AWS CLI installation**:
   ```bash
   aws --version
   ```
   If not installed, follow [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

2. **Verify config file exists**:
   ```bash
   ls -la ~/.aws/config
   ```

3. **List profiles manually**:
   ```bash
   aws configure list-profiles
   ```

4. **Example config file format**:
   ```ini
   [default]
   region = us-east-1
   
   [profile dev]
   region = us-west-2
   
   [profile prod]
   region = us-east-1
   ```

## Authentication Errors

**Problem**: "Access Denied" or authentication failures.

**Solutions**:
1. **Check credentials file**:
   ```bash
   ls -la ~/.aws/credentials
   ```

2. **Test AWS access**:
   ```bash
   aws sts get-caller-identity --profile your-profile-name
   ```

3. **Verify Cost Explorer permissions**:
   - Your IAM user/role needs `ce:GetCostAndUsage` permission
   - Add this policy to your IAM user:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ce:GetCostAndUsage",
           "ce:GetDimensionValues"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

## Rate Limiting Issues

**Problem**: "Rate limit exceeded" errors.

**Explanation**: AWS allows only 1 Cost Explorer API request per minute per account.

**Solutions**:
- **Wait for the cooldown**: The app shows a countdown timer
- **Adjust refresh interval**: Go to Settings → Refresh Rate
- **Use manual refresh sparingly**: Don't click refresh repeatedly
- **Check API usage**: Monitor requests in the Debug section

## Incorrect Cost Data

**Problem**: Costs don't match AWS console.

**Explanations**:
- **Data freshness**: AWS costs can take 24-48 hours to finalize
- **Time zones**: Ensure your Mac's timezone matches AWS region settings  
- **Currency**: Check if you're viewing the same currency in both places
- **Billing period**: Verify you're comparing the same time periods

**Solutions**:
1. **Wait 24-48 hours** for data to stabilize
2. **Check AWS Cost Explorer console** to compare
3. **Verify selected profile** matches the account you expect
4. **Clear cache** and refresh data

## Performance Issues

**Problem**: App is slow or unresponsive.

**Solutions**:
1. **Reduce refresh frequency**: Settings → Refresh Rate → increase interval
2. **Check memory usage**: Activity Monitor → AWSCostMonitor
3. **Restart the app**: Quit and relaunch
4. **Clear cache**: Settings → Debug → Clear Cache

## Menu Bar Icon Missing

**Problem**: Can't find the app icon in menu bar.

**Solutions**:
1. **Check if app is running**: Look in Activity Monitor
2. **Restart the app**: Use Spotlight to launch again
3. **Menu bar space**: Hide other menu bar items to make room
4. **Bartender conflict**: If using Bartender, check if icon is hidden

## App Won't Start

**Problem**: Application fails to launch.

**Solutions**:
1. **macOS compatibility**: Requires macOS 13.0+
2. **Security settings**: 
   - System Preferences → Security & Privacy → General
   - Click "Open Anyway" if prompted
3. **Corrupted download**: Re-download from GitHub releases
4. **Console logs**: Check Console.app for crash reports

## Data Not Refreshing

**Problem**: Cost data appears stale or won't update.

**Solutions**:
1. **Check internet connection**
2. **Verify AWS credentials haven't expired**
3. **Manual refresh**: Click refresh button
4. **Check API limits**: Debug section shows request counts
5. **Service outages**: Check AWS Service Health Dashboard

## Settings Not Saving

**Problem**: App doesn't remember your preferences.

**Solutions**:
1. **Permissions**: Ensure app can write to `~/Library/Preferences/`
2. **Disk space**: Check available storage
3. **Reset preferences**: Delete `~/Library/Preferences/com.middleout.AWSCostMonitor.plist`

## Getting Help

If you're still experiencing issues:

1. **Enable debug logging**: Settings → Debug → Enable Verbose Logging
2. **Export logs**: Settings → Debug → Export Logs
3. **Create an issue**: [GitHub Issues](https://github.com/toml0006/AWSCostMonitor/issues)
4. **Join discussions**: [GitHub Discussions](https://github.com/toml0006/AWSCostMonitor/discussions)
5. **Email support**: awsapp@middleout.dev

When reporting issues, please include:
- AWSCostMonitor version
- macOS version  
- AWS CLI version
- Error messages or logs
- Steps to reproduce

---

**Still stuck?** Check our [Discussions](https://github.com/toml0006/AWSCostMonitor/discussions) or [create an issue](https://github.com/toml0006/AWSCostMonitor/issues).