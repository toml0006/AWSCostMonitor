import React from 'react';
import { Shield, Users, DollarSign, Clock, Database, Key, CheckCircle, AlertCircle } from 'lucide-react';

const TeamCache: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      {/* Hero Section */}
      <section className="px-4 py-20 mx-auto max-w-7xl">
        <div className="text-center">
          <div className="inline-flex items-center px-3 py-1 mb-4 text-sm font-medium text-blue-700 bg-blue-100 rounded-full">
            Pro Feature
          </div>
          <h1 className="text-5xl font-bold text-gray-900 mb-6">
            Team Cache for AWSCostMonitor
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Share AWS cost data efficiently with your team. Reduce API calls by 5-10x while maintaining complete privacy and control.
          </p>
        </div>
      </section>

      {/* How It Works */}
      <section className="px-4 py-16 mx-auto max-w-7xl">
        <h2 className="text-3xl font-bold text-gray-900 mb-8 text-center">How Team Cache Works</h2>
        <div className="grid md:grid-cols-3 gap-6">
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <Database className="w-12 h-12 text-blue-600 mb-4" />
            <h3 className="text-xl font-semibold mb-2">S3-Based Storage</h3>
            <p className="text-gray-600">
              Uses your existing AWS S3 bucket to store cached cost data. Data never leaves your AWS account.
            </p>
          </div>
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <Clock className="w-12 h-12 text-blue-600 mb-4" />
            <h3 className="text-xl font-semibold mb-2">Smart Refresh</h3>
            <p className="text-gray-600">
              Automatic 6-hour refresh cycle with jitter to prevent collisions. 30-minute cooldown for manual refreshes.
            </p>
          </div>
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <Users className="w-12 h-12 text-blue-600 mb-4" />
            <h3 className="text-xl font-semibold mb-2">Full Transparency</h3>
            <p className="text-gray-600">
              See who updated the cache and when. Visual staleness indicators keep everyone informed.
            </p>
          </div>
        </div>
      </section>

      {/* Setup Guide */}
      <section className="px-4 py-16 mx-auto max-w-7xl bg-white rounded-lg">
        <h2 className="text-3xl font-bold text-gray-900 mb-8">Setup Guide</h2>
        
        <div className="space-y-8">
          {/* Step 1: Create S3 Bucket */}
          <div className="border-l-4 border-blue-500 pl-6">
            <h3 className="text-2xl font-semibold mb-4">Step 1: Create S3 Bucket</h3>
            <p className="text-gray-600 mb-4">
              Create a dedicated S3 bucket for your team's cache storage. Choose a region close to your team for best performance.
            </p>
            <div className="bg-gray-50 rounded-lg p-4 font-mono text-sm">
              <p># Using AWS CLI</p>
              <p>aws s3 mb s3://your-team-awscost-cache --region us-east-1</p>
            </div>
            <div className="mt-4 p-4 bg-blue-50 rounded-lg">
              <p className="text-sm text-blue-800">
                <strong>Tip:</strong> Use a descriptive name like `teamname-awscost-cache` to identify the bucket purpose.
              </p>
            </div>
          </div>

          {/* Step 2: Configure IAM Permissions */}
          <div className="border-l-4 border-blue-500 pl-6">
            <h3 className="text-2xl font-semibold mb-4">Step 2: Configure IAM Permissions</h3>
            <p className="text-gray-600 mb-4">
              Each team member needs the following IAM permissions for the cache bucket:
            </p>
            <div className="bg-gray-50 rounded-lg p-4 overflow-x-auto">
              <pre className="text-sm">{`{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TeamCacheAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:HeadObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-team-awscost-cache/*",
        "arn:aws:s3:::your-team-awscost-cache"
      ]
    },
    {
      "Sid": "CostExplorerAccess",
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast"
      ],
      "Resource": "*"
    }
  ]
}`}</pre>
            </div>
          </div>

          {/* Step 3: Enable in AWSCostMonitor */}
          <div className="border-l-4 border-blue-500 pl-6">
            <h3 className="text-2xl font-semibold mb-4">Step 3: Enable in AWSCostMonitor</h3>
            <ol className="list-decimal list-inside space-y-3 text-gray-600">
              <li>Open AWSCostMonitor Settings</li>
              <li>Navigate to the "Refresh Settings" tab</li>
              <li>Select your AWS profile</li>
              <li>Toggle "Enable Team Cache" to ON</li>
              <li>Enter your S3 bucket details:
                <ul className="list-disc list-inside ml-6 mt-2">
                  <li>S3 Bucket Name: <code className="bg-gray-100 px-2 py-1 rounded">your-team-awscost-cache</code></li>
                  <li>S3 Region: <code className="bg-gray-100 px-2 py-1 rounded">us-east-1</code></li>
                  <li>Team ID: <code className="bg-gray-100 px-2 py-1 rounded">your-team-name</code></li>
                </ul>
              </li>
              <li>Click "Test S3 Connection" to verify setup</li>
              <li>Save settings</li>
            </ol>
          </div>

          {/* Step 4: Verify Setup */}
          <div className="border-l-4 border-blue-500 pl-6">
            <h3 className="text-2xl font-semibold mb-4">Step 4: Verify Setup</h3>
            <p className="text-gray-600 mb-4">
              After enabling Team Cache, verify it's working correctly:
            </p>
            <div className="space-y-2">
              <div className="flex items-start">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5 mr-2 flex-shrink-0" />
                <span className="text-gray-600">Check the Team Cache status indicator in the app</span>
              </div>
              <div className="flex items-start">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5 mr-2 flex-shrink-0" />
                <span className="text-gray-600">Verify cache data appears in your S3 bucket</span>
              </div>
              <div className="flex items-start">
                <CheckCircle className="w-5 h-5 text-green-500 mt-0.5 mr-2 flex-shrink-0" />
                <span className="text-gray-600">Confirm other team members can read the cache</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Cache Structure */}
      <section className="px-4 py-16 mx-auto max-w-7xl">
        <h2 className="text-3xl font-bold text-gray-900 mb-8">Cache Structure</h2>
        <div className="bg-white rounded-lg p-6">
          <p className="text-gray-600 mb-4">
            Team Cache organizes data in S3 with the following structure:
          </p>
          <div className="bg-gray-50 rounded-lg p-4 font-mono text-sm">
            <p>s3://your-bucket/</p>
            <p>  └── teams/</p>
            <p>      └── your-team-id/</p>
            <p>          ├── cache.json        # Current cost snapshot</p>
            <p>          ├── cache.lock        # Soft lock for concurrency</p>
            <p>          └── audit/            # Optional audit logs</p>
            <p>              └── 2025-08-22/</p>
            <p>                  └── *.json</p>
          </div>
        </div>
      </section>

      {/* Benefits */}
      <section className="px-4 py-16 mx-auto max-w-7xl">
        <h2 className="text-3xl font-bold text-gray-900 mb-8 text-center">Benefits for Your Team</h2>
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="text-center">
            <DollarSign className="w-12 h-12 text-green-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">Reduce API Costs</h3>
            <p className="text-gray-600">Cut AWS API calls by 5-10x, saving money on every refresh</p>
          </div>
          <div className="text-center">
            <Shield className="w-12 h-12 text-blue-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">Maintain Privacy</h3>
            <p className="text-gray-600">Data stays in your AWS account with your existing security</p>
          </div>
          <div className="text-center">
            <Clock className="w-12 h-12 text-purple-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">Faster Updates</h3>
            <p className="text-gray-600">Instant data from cache instead of waiting for API calls</p>
          </div>
          <div className="text-center">
            <Key className="w-12 h-12 text-orange-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">Full Control</h3>
            <p className="text-gray-600">Use your existing IAM policies and S3 encryption</p>
          </div>
        </div>
      </section>

      {/* Troubleshooting */}
      <section className="px-4 py-16 mx-auto max-w-7xl bg-gray-50 rounded-lg">
        <h2 className="text-3xl font-bold text-gray-900 mb-8">Troubleshooting</h2>
        
        <div className="space-y-6">
          <div className="bg-white rounded-lg p-6">
            <div className="flex items-start">
              <AlertCircle className="w-6 h-6 text-yellow-600 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <h3 className="text-lg font-semibold mb-2">S3 Connection Failed</h3>
                <p className="text-gray-600 mb-2">Check that:</p>
                <ul className="list-disc list-inside text-gray-600 space-y-1">
                  <li>The S3 bucket name is correct and exists</li>
                  <li>The AWS region matches your bucket's region</li>
                  <li>Your AWS profile has the required S3 permissions</li>
                  <li>Your AWS credentials are valid and not expired</li>
                </ul>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg p-6">
            <div className="flex items-start">
              <AlertCircle className="w-6 h-6 text-yellow-600 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <h3 className="text-lg font-semibold mb-2">Cache Not Updating</h3>
                <p className="text-gray-600 mb-2">Verify that:</p>
                <ul className="list-disc list-inside text-gray-600 space-y-1">
                  <li>At least one team member has write permissions</li>
                  <li>The 6-hour auto-refresh timer hasn't been disabled</li>
                  <li>No team member is stuck holding the cache lock</li>
                  <li>The cache data isn't corrupted (try clearing it)</li>
                </ul>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg p-6">
            <div className="flex items-start">
              <AlertCircle className="w-6 h-6 text-yellow-600 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <h3 className="text-lg font-semibold mb-2">Permission Denied Errors</h3>
                <p className="text-gray-600 mb-2">Ensure:</p>
                <ul className="list-disc list-inside text-gray-600 space-y-1">
                  <li>IAM policy includes all required S3 actions</li>
                  <li>Resource ARNs match your bucket name exactly</li>
                  <li>No explicit Deny statements override permissions</li>
                  <li>S3 bucket policy doesn't block access</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Best Practices */}
      <section className="px-4 py-16 mx-auto max-w-7xl">
        <h2 className="text-3xl font-bold text-gray-900 mb-8">Best Practices</h2>
        <div className="grid md:grid-cols-2 gap-6">
          <div className="bg-white rounded-lg p-6">
            <h3 className="text-xl font-semibold mb-3">🔒 Security</h3>
            <ul className="space-y-2 text-gray-600">
              <li>• Use S3 encryption (SSE-S3 or SSE-KMS)</li>
              <li>• Implement least-privilege IAM policies</li>
              <li>• Use separate buckets for different teams</li>
              <li>• Enable S3 access logging for audit trails</li>
            </ul>
          </div>
          <div className="bg-white rounded-lg p-6">
            <h3 className="text-xl font-semibold mb-3">⚡ Performance</h3>
            <ul className="space-y-2 text-gray-600">
              <li>• Choose S3 region close to your team</li>
              <li>• Let auto-refresh handle updates</li>
              <li>• Avoid manual refresh unless necessary</li>
              <li>• Monitor cache staleness indicators</li>
            </ul>
          </div>
          <div className="bg-white rounded-lg p-6">
            <h3 className="text-xl font-semibold mb-3">👥 Team Coordination</h3>
            <ul className="space-y-2 text-gray-600">
              <li>• Communicate bucket name to all members</li>
              <li>• Use consistent Team ID across the team</li>
              <li>• Document your setup for new members</li>
              <li>• Monitor who's updating the cache</li>
            </ul>
          </div>
          <div className="bg-white rounded-lg p-6">
            <h3 className="text-xl font-semibold mb-3">📊 Monitoring</h3>
            <ul className="space-y-2 text-gray-600">
              <li>• Check cache freshness regularly</li>
              <li>• Review S3 costs monthly</li>
              <li>• Enable audit logging if needed</li>
              <li>• Track API call reduction metrics</li>
            </ul>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="px-4 py-16 mx-auto max-w-7xl">
        <h2 className="text-3xl font-bold text-gray-900 mb-8 text-center">Frequently Asked Questions</h2>
        <div className="space-y-6 max-w-3xl mx-auto">
          <details className="bg-white rounded-lg p-6">
            <summary className="font-semibold cursor-pointer">Is Team Cache available in the open-source version?</summary>
            <p className="mt-3 text-gray-600">
              Team Cache is currently a Pro feature available only in the App Store version. This helps support continued development of AWSCostMonitor.
            </p>
          </details>
          
          <details className="bg-white rounded-lg p-6">
            <summary className="font-semibold cursor-pointer">How much does S3 storage cost for Team Cache?</summary>
            <p className="mt-3 text-gray-600">
              Minimal. Cache files are typically under 100KB. At $0.023 per GB per month, you're looking at less than $0.01 per month for storage, plus minimal request costs.
            </p>
          </details>
          
          <details className="bg-white rounded-lg p-6">
            <summary className="font-semibold cursor-pointer">Can I use Team Cache across AWS accounts?</summary>
            <p className="mt-3 text-gray-600">
              Yes! As long as each AWS profile has access to the same S3 bucket, you can share cache data across different AWS accounts. Use cross-account IAM roles or bucket policies.
            </p>
          </details>
          
          <details className="bg-white rounded-lg p-6">
            <summary className="font-semibold cursor-pointer">What happens if the cache is corrupted?</summary>
            <p className="mt-3 text-gray-600">
              AWSCostMonitor automatically falls back to direct API calls if the cache is unreadable. The next successful refresh will overwrite the corrupted cache.
            </p>
          </details>
          
          <details className="bg-white rounded-lg p-6">
            <summary className="font-semibold cursor-pointer">How do I disable Team Cache?</summary>
            <p className="mt-3 text-gray-600">
              Simply toggle off "Enable Team Cache" in Settings &gt; Refresh Settings for each profile. The app will immediately revert to direct API calls.
            </p>
          </details>
        </div>
      </section>

      {/* CTA */}
      <section className="px-4 py-20 mx-auto max-w-7xl text-center">
        <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-12 text-white">
          <h2 className="text-3xl font-bold mb-4">Ready to Optimize Your Team's AWS Cost Monitoring?</h2>
          <p className="text-xl mb-8 opacity-90">
            Get AWSCostMonitor Pro from the App Store and start saving on API calls today.
          </p>
          <a
            href="https://apps.apple.com/app/awscostmonitor"
            className="inline-flex items-center px-8 py-3 bg-white text-blue-600 rounded-lg font-semibold hover:bg-gray-100 transition-colors"
          >
            Get from App Store
          </a>
        </div>
      </section>
    </div>
  );
};

export default TeamCache;