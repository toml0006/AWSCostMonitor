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

      <style jsx>{`
        .installation {
          background: var(--color-light);
        }

        .section-header {
          text-align: center;
          margin-bottom: var(--space-3xl);
        }

        .installation-content {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: var(--space-3xl);
          margin-bottom: var(--space-3xl);
        }

        .installation-steps h3,
        .installation-benefits h3 {
          margin-bottom: var(--space-xl);
          font-size: 1.5rem;
        }

        .step {
          display: flex;
          gap: var(--space-lg);
          margin-bottom: var(--space-xl);
          align-items: flex-start;
        }

        .step-number {
          width: 40px;
          height: 40px;
          background: var(--color-primary);
          color: white;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 700;
          flex-shrink: 0;
        }

        .step-content h4 {
          margin-bottom: 0.5rem;
          font-size: 1.1rem;
        }

        .step-content p {
          margin-bottom: 1rem;
          color: var(--color-text-secondary);
        }

        .download-btn {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          background: var(--color-primary);
          color: white;
          padding: 0.75rem 1.5rem;
          border-radius: var(--radius-md);
          text-decoration: none;
          font-weight: 600;
          transition: all 0.3s ease;
          border: none;
          cursor: pointer;
        }

        .download-btn:hover {
          background: var(--color-primary-dark);
          transform: translateY(-2px);
        }

        .link-btn {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          color: var(--color-primary);
          text-decoration: none;
          font-weight: 500;
          transition: color 0.3s ease;
        }

        .link-btn:hover {
          color: var(--color-primary-dark);
        }

        .link-btn.small {
          font-size: 0.875rem;
        }

        .code-snippet {
          background: var(--color-dark);
          color: var(--color-light);
          padding: 0.75rem 1rem;
          border-radius: var(--radius-md);
          font-family: 'Monaco', 'Consolas', monospace;
          margin: 0.5rem 0 1rem 0;
        }

        .permissions-list {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
          margin: 0.5rem 0 1rem 0;
        }

        .permission {
          background: var(--color-accent);
          padding: 0.5rem 0.75rem;
          border-radius: var(--radius-sm);
          font-family: 'Monaco', 'Consolas', monospace;
          font-size: 0.875rem;
        }

        .installation-benefits {
          display: flex;
          flex-direction: column;
          gap: var(--space-lg);
        }

        .benefit-card {
          background: white;
          padding: var(--space-lg);
          border-radius: var(--radius-lg);
          box-shadow: var(--shadow-sm);
          border: 1px solid var(--color-border);
        }

        .benefit-icon {
          width: 48px;
          height: 48px;
          background: var(--color-primary);
          color: white;
          border-radius: var(--radius-md);
          display: flex;
          align-items: center;
          justify-content: center;
          margin-bottom: 1rem;
        }

        .benefit-card h4 {
          margin-bottom: 0.5rem;
          font-size: 1.1rem;
        }

        .benefit-card p {
          color: var(--color-text-secondary);
          line-height: 1.6;
        }

        .api-cost-info {
          background: white;
          padding: var(--space-2xl);
          border-radius: var(--radius-lg);
          box-shadow: var(--shadow-md);
        }

        .api-cost-info h3 {
          margin-bottom: var(--space-lg);
          text-align: center;
        }

        .cost-breakdown {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: var(--space-md);
          margin-bottom: var(--space-lg);
        }

        .cost-item {
          padding: var(--space-md);
          background: var(--color-light);
          border-radius: var(--radius-md);
          text-align: center;
        }

        .cost-guarantee {
          display: flex;
          gap: var(--space-md);
          align-items: flex-start;
          padding: var(--space-lg);
          background: var(--color-accent);
          border-radius: var(--radius-md);
          border-left: 4px solid var(--color-primary);
        }

        .cost-guarantee svg {
          color: var(--color-primary);
          flex-shrink: 0;
          margin-top: 2px;
        }

        @media (max-width: 768px) {
          .installation-content {
            grid-template-columns: 1fr;
            gap: var(--space-xl);
          }

          .cost-breakdown {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </section>
  )
}

export default Installation