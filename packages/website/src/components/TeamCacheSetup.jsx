import { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  Cloud, 
  Shield, 
  DollarSign, 
  CheckCircle, 
  Copy, 
  AlertCircle,
  Terminal,
  FileCode,
  Settings,
  Users,
  Zap,
  TrendingDown,
  Info,
  ExternalLink,
  ChevronRight
} from 'lucide-react'

function TeamCacheSetup() {
  const [copiedCode, setCopiedCode] = useState(null)

  const copyToClipboard = (code, id) => {
    navigator.clipboard.writeText(code)
    setCopiedCode(id)
    setTimeout(() => setCopiedCode(null), 2000)
  }

  const codeBlocks = {
    createBucketCLI: `# Create the bucket
aws s3api create-bucket \\
  --bucket myteam-awscost-cache \\
  --region us-east-1

# Enable encryption
aws s3api put-bucket-encryption \\
  --bucket myteam-awscost-cache \\
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'`,
    
    iamPolicy: `{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::myteam-awscost-cache",
        "arn:aws:s3:::myteam-awscost-cache/*"
      ]
    },
    {
      "Sid": "STSAccess",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CostExplorerAccess",
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage"
      ],
      "Resource": "*"
    }
  ]
}`,

    testPermissions: `# Test STS access
aws sts get-caller-identity

# Test S3 read access
aws s3 ls s3://myteam-awscost-cache/

# Test S3 write access
echo "test" | aws s3 cp - s3://myteam-awscost-cache/test.txt

# Test S3 delete access
aws s3 rm s3://myteam-awscost-cache/test.txt`
  }

  return (
    <div className="team-cache-setup">
      <div className="container">
        {/* Header */}
        <motion.div 
          className="setup-header"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <div className="header-content">
            <h1 className="page-title">
              <Users className="title-icon" />
              Team Cache Setup Guide
            </h1>
            <p className="page-subtitle">
              Share AWS cost data across your team and reduce API calls by 90%
            </p>
          </div>
        </motion.div>

        {/* Benefits Section */}
        <motion.section 
          className="benefits-section"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
        >
          <h2 className="section-title">Why Use Team Cache?</h2>
          <div className="benefits-grid">
            <div className="benefit-card">
              <div className="benefit-icon">
                <TrendingDown />
              </div>
              <h3>90% Fewer API Calls</h3>
              <p>Share cached data across your team instead of making redundant calls</p>
            </div>
            <div className="benefit-card">
              <div className="benefit-icon">
                <DollarSign />
              </div>
              <h3>Save Money</h3>
              <p>Reduce AWS Cost Explorer API costs from $144/month to $14/month for a 10-person team</p>
            </div>
            <div className="benefit-card">
              <div className="benefit-icon">
                <Zap />
              </div>
              <h3>Faster Performance</h3>
              <p>Retrieve data from S3 cache instantly instead of waiting for API calls</p>
            </div>
            <div className="benefit-card">
              <div className="benefit-icon">
                <Shield />
              </div>
              <h3>Privacy-First</h3>
              <p>Uses your existing AWS infrastructure - no third-party services</p>
            </div>
          </div>
        </motion.section>

        {/* Prerequisites */}
        <motion.section 
          className="prerequisites-section"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          <h2 className="section-title">Prerequisites</h2>
          <div className="prereq-list">
            <div className="prereq-item">
              <CheckCircle className="check-icon" />
              <span>AWS Account with appropriate permissions</span>
            </div>
            <div className="prereq-item">
              <CheckCircle className="check-icon" />
              <span>S3 Bucket for storing cache data (or ability to create one)</span>
            </div>
            <div className="prereq-item">
              <CheckCircle className="check-icon" />
              <span>IAM Permissions for both S3 and STS services</span>
            </div>
            <div className="prereq-item">
              <CheckCircle className="check-icon" />
              <span>AWSCostMonitor Pro (Team Cache is a Pro feature)</span>
            </div>
          </div>
        </motion.section>

        {/* Setup Steps */}
        <motion.section 
          className="setup-steps"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
        >
          <h2 className="section-title">Setup Steps</h2>

          {/* Step 1: Create S3 Bucket */}
          <div className="setup-step">
            <div className="step-header">
              <div className="step-number">1</div>
              <h3>Create an S3 Bucket</h3>
            </div>
            
            <div className="step-content">
              <div className="step-option">
                <h4>Option A: Using AWS Console</h4>
                <ol className="step-list">
                  <li>Open the <a href="https://console.aws.amazon.com/s3/" target="_blank" rel="noopener noreferrer">AWS S3 Console <ExternalLink className="inline-icon" /></a></li>
                  <li>Click <strong>Create bucket</strong></li>
                  <li>Enter a globally unique bucket name (e.g., <code>myteam-awscost-cache</code>)</li>
                  <li>Select your preferred AWS Region</li>
                  <li>Keep default settings for security and encryption</li>
                  <li>Click <strong>Create bucket</strong></li>
                </ol>
              </div>

              <div className="step-option">
                <h4>Option B: Using AWS CLI</h4>
                <div className="code-block">
                  <div className="code-header">
                    <span className="code-lang">bash</span>
                    <button 
                      className={`copy-button ${copiedCode === 'createBucketCLI' ? 'copied' : ''}`}
                      onClick={() => copyToClipboard(codeBlocks.createBucketCLI, 'createBucketCLI')}
                    >
                      {copiedCode === 'createBucketCLI' ? (
                        <>
                          <CheckCircle className="copy-icon" />
                          Copied!
                        </>
                      ) : (
                        <>
                          <Copy className="copy-icon" />
                          Copy
                        </>
                      )}
                    </button>
                  </div>
                  <pre>{codeBlocks.createBucketCLI}</pre>
                </div>
              </div>
            </div>
          </div>

          {/* Step 2: Configure IAM */}
          <div className="setup-step">
            <div className="step-header">
              <div className="step-number">2</div>
              <h3>Configure IAM Permissions</h3>
            </div>
            
            <div className="step-content">
              <p>Create an IAM policy named <code>AWSCostMonitorTeamCache</code> with the following permissions:</p>
              
              <div className="code-block">
                <div className="code-header">
                  <span className="code-lang">json</span>
                  <button 
                    className={`copy-button ${copiedCode === 'iamPolicy' ? 'copied' : ''}`}
                    onClick={() => copyToClipboard(codeBlocks.iamPolicy, 'iamPolicy')}
                  >
                    {copiedCode === 'iamPolicy' ? (
                      <>
                        <CheckCircle className="copy-icon" />
                        Copied!
                      </>
                    ) : (
                      <>
                        <Copy className="copy-icon" />
                        Copy
                      </>
                    )}
                  </button>
                </div>
                <pre>{codeBlocks.iamPolicy}</pre>
              </div>

              <div className="info-box">
                <Info className="info-icon" />
                <p>Remember to replace <code>myteam-awscost-cache</code> with your actual bucket name in the policy.</p>
              </div>
            </div>
          </div>

          {/* Step 3: Enable in App */}
          <div className="setup-step">
            <div className="step-header">
              <div className="step-number">3</div>
              <h3>Enable Team Cache in AWSCostMonitor</h3>
            </div>
            
            <div className="step-content">
              <ol className="step-list">
                <li>Open AWSCostMonitor</li>
                <li>Open <strong>Preferences</strong> (⌘,)</li>
                <li>Navigate to the <strong>Team Cache</strong> tab</li>
                <li>Select your AWS profile from the dropdown</li>
                <li>Toggle <strong>"Enable team cache for this profile"</strong> to ON</li>
                <li>Configure the following settings:
                  <ul>
                    <li><strong>S3 Bucket Name:</strong> Your bucket name (e.g., <code>myteam-awscost-cache</code>)</li>
                    <li><strong>S3 Region:</strong> The region where your bucket is located</li>
                    <li><strong>Cache Prefix:</strong> A prefix for organizing cache files (default: <code>awscost-team-cache</code>)</li>
                  </ul>
                </li>
                <li>Click <strong>Test Connection</strong> to verify setup</li>
              </ol>
            </div>
          </div>

          {/* Step 4: Verify */}
          <div className="setup-step">
            <div className="step-header">
              <div className="step-number">4</div>
              <h3>Verify Team Cache is Working</h3>
            </div>
            
            <div className="step-content">
              <h4>Test Permissions with AWS CLI</h4>
              <div className="code-block">
                <div className="code-header">
                  <span className="code-lang">bash</span>
                  <button 
                    className={`copy-button ${copiedCode === 'testPermissions' ? 'copied' : ''}`}
                    onClick={() => copyToClipboard(codeBlocks.testPermissions, 'testPermissions')}
                  >
                    {copiedCode === 'testPermissions' ? (
                      <>
                        <CheckCircle className="copy-icon" />
                        Copied!
                      </>
                    ) : (
                      <>
                        <Copy className="copy-icon" />
                        Copy
                      </>
                    )}
                  </button>
                </div>
                <pre>{codeBlocks.testPermissions}</pre>
              </div>

              <h4>Check Cache in S3</h4>
              <ol className="step-list">
                <li>Click refresh in AWSCostMonitor or wait for automatic refresh</li>
                <li>Open your S3 bucket in the AWS Console</li>
                <li>Navigate to: <code>awscost-team-cache/cache-v1/[ACCOUNT_ID]/[YYYY-MM]/</code></li>
                <li>You should see a file named <code>full-data.json.gz</code></li>
              </ol>

              <h4>View Cache Statistics</h4>
              <p>In Team Cache settings, click <strong>Show Statistics</strong> to see cache hits, misses, and hit ratio.</p>
            </div>
          </div>
        </motion.section>

        {/* Cost Comparison */}
        <motion.section 
          className="cost-comparison"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
        >
          <h2 className="section-title">Cost Savings Example</h2>
          <div className="cost-cards">
            <div className="cost-card without-cache">
              <h3>Without Team Cache</h3>
              <div className="cost-details">
                <p>10 team members</p>
                <p>48 refreshes/day each</p>
                <p>30 days/month</p>
                <div className="cost-calc">
                  = 14,400 API calls/month
                </div>
                <div className="cost-total">
                  <span className="cost-amount">$144</span>
                  <span className="cost-period">/month</span>
                </div>
              </div>
            </div>

            <div className="cost-arrow">
              <ChevronRight />
            </div>

            <div className="cost-card with-cache">
              <h3>With Team Cache</h3>
              <div className="cost-details">
                <p>1 shared cache</p>
                <p>48 refreshes/day</p>
                <p>30 days/month</p>
                <div className="cost-calc">
                  = 1,440 API calls/month
                </div>
                <div className="cost-total">
                  <span className="cost-amount">$14.40</span>
                  <span className="cost-period">/month</span>
                </div>
              </div>
              <div className="savings-badge">
                Save $129.60/month (90%)
              </div>
            </div>
          </div>
        </motion.section>

        {/* Troubleshooting */}
        <motion.section 
          className="troubleshooting"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.5 }}
        >
          <h2 className="section-title">Troubleshooting</h2>
          <div className="troubleshooting-items">
            <details className="trouble-item">
              <summary>
                <AlertCircle className="trouble-icon" />
                <span>"Connection failed" Error</span>
              </summary>
              <div className="trouble-content">
                <ul>
                  <li>Verify S3 bucket exists and is accessible</li>
                  <li>Check IAM permissions are correctly configured</li>
                  <li>Ensure AWS credentials are properly configured (<code>~/.aws/credentials</code>)</li>
                </ul>
              </div>
            </details>

            <details className="trouble-item">
              <summary>
                <AlertCircle className="trouble-icon" />
                <span>"Could not resolve account ID" Error</span>
              </summary>
              <div className="trouble-content">
                <ul>
                  <li>Add STS permissions to your IAM policy</li>
                  <li>Verify <code>sts:GetCallerIdentity</code> permission is granted</li>
                </ul>
              </div>
            </details>

            <details className="trouble-item">
              <summary>
                <AlertCircle className="trouble-icon" />
                <span>Cache Not Being Written</span>
              </summary>
              <div className="trouble-content">
                <ul>
                  <li>Check S3 bucket permissions for <code>s3:PutObject</code></li>
                  <li>Verify bucket name and region are correct</li>
                  <li>Look for error messages in Console.app</li>
                </ul>
              </div>
            </details>

            <details className="trouble-item">
              <summary>
                <AlertCircle className="trouble-icon" />
                <span>Cache Not Being Read</span>
              </summary>
              <div className="trouble-content">
                <ul>
                  <li>Ensure <code>s3:GetObject</code> permission is granted</li>
                  <li>Check if cache files exist in S3</li>
                  <li>Verify team members are using the same bucket and prefix</li>
                </ul>
              </div>
            </details>
          </div>
        </motion.section>

        {/* Security Best Practices */}
        <motion.section 
          className="security-section"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.6 }}
        >
          <h2 className="section-title">
            <Shield className="section-icon" />
            Security Best Practices
          </h2>
          <div className="security-list">
            <div className="security-item">
              <CheckCircle className="check-icon" />
              <div>
                <strong>Use Encryption:</strong> Enable SSE-S3 or SSE-KMS encryption on your S3 bucket
              </div>
            </div>
            <div className="security-item">
              <CheckCircle className="check-icon" />
              <div>
                <strong>Restrict Access:</strong> Only grant team members the minimum required permissions
              </div>
            </div>
            <div className="security-item">
              <CheckCircle className="check-icon" />
              <div>
                <strong>Enable Versioning:</strong> Consider enabling S3 versioning for data recovery
              </div>
            </div>
            <div className="security-item">
              <CheckCircle className="check-icon" />
              <div>
                <strong>Monitor Access:</strong> Enable S3 access logging to track usage
              </div>
            </div>
            <div className="security-item">
              <CheckCircle className="check-icon" />
              <div>
                <strong>Regular Audits:</strong> Review IAM policies and bucket permissions quarterly
              </div>
            </div>
          </div>
        </motion.section>

        {/* Support Section */}
        <motion.section 
          className="support-section"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.7 }}
        >
          <h2 className="section-title">Need Help?</h2>
          <div className="support-options">
            <a href="https://github.com/toml0006/AWSCostMonitor/issues" target="_blank" rel="noopener noreferrer" className="support-link">
              <Terminal className="support-icon" />
              <span>Report Issues on GitHub</span>
              <ExternalLink className="link-icon" />
            </a>
            <a href="/" className="support-link">
              <FileCode className="support-icon" />
              <span>View Documentation</span>
            </a>
          </div>
        </motion.section>
      </div>
    </div>
  )
}

export default TeamCacheSetup