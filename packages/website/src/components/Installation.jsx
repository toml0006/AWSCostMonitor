import { motion } from 'framer-motion'
import { Download, ExternalLink, Shield, DollarSign, Clock, Lock } from 'lucide-react'

const Installation = () => {
  return (
    <section id="installation" className="installation">
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
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
                <button className="download-btn">
                  <Download size={20} />
                  Download for macOS
                </button>
              </div>
            </div>

            <div className="step">
              <div className="step-number">2</div>
              <div className="step-content">
                <h4>Install AWS CLI</h4>
                <p>Configure AWS CLI with your credentials and profiles</p>
                <a href="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" 
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
                <a href="https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html" 
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
                  <div className="permission">ce:GetCostAndUsage</div>
                  <div className="permission">ce:GetUsageReport</div>
                </div>
                <a href="https://docs.aws.amazon.com/cost-management/latest/userguide/ce-access.html" 
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
              <strong>Cost Explorer API:</strong> $0.01 per request
            </div>
            <div className="cost-item">
              <strong>Our Rate Limit:</strong> Maximum 1 request per minute
            </div>
            <div className="cost-item">
              <strong>Monthly Maximum:</strong> ~$4.32 (43,200 minutes × $0.01)
            </div>
            <div className="cost-item">
              <strong>Typical Usage:</strong> $0.50-$2.00/month with smart refresh
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