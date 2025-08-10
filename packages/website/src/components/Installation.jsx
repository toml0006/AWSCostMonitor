import { motion } from 'framer-motion'
import { Download, ExternalLink, Shield, DollarSign, Clock, Lock, AlertCircle } from 'lucide-react'

// Inline constants to fix build
const EXTERNAL_LINKS = {
  awsCLIInstall: 'https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html',
  awsCLIConfig: 'https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html',
  costExplorerPermissions: 'https://docs.aws.amazon.com/cost-management/latest/userguide/ce-iam-policy.html'
}

const AWS_PERMISSIONS = [
  'ce:GetCostAndUsage',
  'ce:GetCostForecast',
  'ce:DescribeCostCategoryDefinition'
]

const AWS_API_COSTS = {
  costExplorerPerRequest: 0.01,
  maxRequestsPerMinute: 1,
  maxMonthlyCost: 432,
  maxMonthlyRequests: 43200,
  typicalMonthlyCost: { min: 5, max: 15 }
}

const ANIMATION_VARIANTS = {
  fadeInUp: {
    initial: { opacity: 0, y: 20 },
    whileInView: { opacity: 1, y: 0 },
    transition: { duration: 0.5 },
    viewport: { once: true }
  }
}

const formatCurrency = (amount) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: amount < 1 ? 2 : 0,
    maximumFractionDigits: 2
  }).format(amount)
}

const Installation = () => {
  return (
    <section id="installation" className="installation">
      <div className="container">
        <motion.div
          {...ANIMATION_VARIANTS.fadeInUp}
          className="section-header"
        >
          <h2>Get <span className="text-gradient">Started</span></h2>
          <p>Simple installation with privacy-first design and cost-aware API usage</p>
        </motion.div>

        <div className="installation-content">
          {/* Installation Steps */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            viewport={{ once: true }}
            className="installation-steps"
          >
            <h3>Installation & Setup</h3>
            
            <div className="step">
              <div className="step-number">1</div>
              <div className="step-content">
                <h4>Download AWS Cost Monitor</h4>
                <p>Get the latest release for macOS (requires macOS 13.0+)</p>
                <a href="https://github.com/toml0006/AWSCostMonitor/releases" 
                   target="_blank" 
                   rel="noopener noreferrer"
                   className="download-btn">
                  <Download size={20} />
                  Download for macOS
                </a>
                <div className="warning-note">
                  <AlertCircle size={16} />
                  <span>
                    Note: You'll see a security dialog about opening an app downloaded from the internet. 
                    <a href="#/unsigned-app-guide" style={{color: 'var(--color-primary)', marginLeft: '4px'}}>
                      Learn how to open it →
                    </a>
                  </span>
                </div>
              </div>
            </div>

            <div className="step">
              <div className="step-number">2</div>
              <div className="step-content">
                <h4>Install AWS CLI</h4>
                <p>Configure AWS CLI with your credentials and profiles</p>
                <a href={EXTERNAL_LINKS.awsCLIInstall} 
                   target="_blank" 
                   rel="noopener noreferrer"
                   className="link-btn">
                  AWS CLI Installation Guide <ExternalLink size={16} />
                </a>
              </div>
            </div>

            <div className="step">
              <div className="step-number">3</div>
              <div className="step-content">
                <h4>Configure AWS Credentials</h4>
                <p>Set up your AWS profiles and ensure Cost Explorer permissions</p>
                <div className="code-snippet">
                  <code>aws configure --profile your-profile</code>
                </div>
                <a href={EXTERNAL_LINKS.awsCLIConfig} 
                   target="_blank" 
                   rel="noopener noreferrer"
                   className="link-btn small">
                  Configuration Guide <ExternalLink size={14} />
                </a>
              </div>
            </div>

            <div className="step">
              <div className="step-number">4</div>
              <div className="step-content">
                <h4>Required Permissions</h4>
                <p>Ensure your IAM user/role has Cost Explorer access</p>
                <div className="permissions-list">
                  {AWS_PERMISSIONS.map((permission, index) => (
                    <div key={index} className="permission">{permission}</div>
                  ))}
                </div>
                <a href={EXTERNAL_LINKS.costExplorerPermissions} 
                   target="_blank" 
                   rel="noopener noreferrer"
                   className="link-btn small">
                  Permissions Guide <ExternalLink size={14} />
                </a>
              </div>
            </div>
          </motion.div>

          {/* Key Benefits */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            viewport={{ once: true }}
            className="installation-benefits"
          >
            <div className="benefit-card">
              <div className="benefit-icon">
                <Lock />
              </div>
              <h4>Privacy First</h4>
              <p>All data stays local on your Mac. No external services, no telemetry, no analytics tracking.</p>
            </div>

            <div className="benefit-card">
              <div className="benefit-icon">
                <DollarSign />
              </div>
              <h4>Cost Aware</h4>
              <p>AWS Cost Explorer API costs ~$0.01 per request. We limit to 1 request per minute with smart caching.</p>
            </div>

            <div className="benefit-card">
              <div className="benefit-icon">
                <Clock />
              </div>
              <h4>Smart Refresh</h4>
              <p>Intelligent refresh rates based on your budget usage. Higher spend = more frequent updates.</p>
            </div>

            <div className="benefit-card">
              <div className="benefit-icon">
                <Shield />
              </div>
              <h4>API Protection</h4>
              <p>Hard rate limits prevent runaway API calls. Emergency kill switch if something goes wrong.</p>
            </div>
          </motion.div>
        </div>

        {/* API Cost Information */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          viewport={{ once: true }}
          className="api-cost-info"
        >
          <h3>Understanding API Costs</h3>
          <div className="cost-breakdown">
            <div className="cost-item">
              <strong>Cost Explorer API:</strong> {formatCurrency(AWS_API_COSTS.costExplorerPerRequest)} per request
            </div>
            <div className="cost-item">
              <strong>Our Rate Limit:</strong> Maximum {AWS_API_COSTS.maxRequestsPerMinute} request per minute
            </div>
            <div className="cost-item">
              <strong>Monthly Maximum:</strong> ~{formatCurrency(AWS_API_COSTS.maxMonthlyCost)} ({AWS_API_COSTS.maxMonthlyRequests.toLocaleString()} minutes × {formatCurrency(AWS_API_COSTS.costExplorerPerRequest)})
            </div>
            <div className="cost-item">
              <strong>Typical Usage:</strong> {formatCurrency(AWS_API_COSTS.typicalMonthlyCost.min)}-{formatCurrency(AWS_API_COSTS.typicalMonthlyCost.max)}/month with smart refresh
            </div>
          </div>
          <div className="cost-guarantee">
            <Shield size={24} />
            <div>
              <strong>Our Guarantee:</strong> We aggressively cache data and enforce strict rate limits. 
              The app will never exceed 1 API call per minute, protecting you from unexpected costs.
            </div>
          </div>
        </motion.div>
      </div>

    </section>
  )
}

export default Installation