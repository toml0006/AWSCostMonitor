import { motion } from 'framer-motion'
import { 
  DollarSign, 
  TrendingDown, 
  Bell, 
  Shield, 
  Zap, 
  Eye,
  Users,
  RefreshCw,
  BarChart3,
  Lock
} from 'lucide-react'

const features = [
  {
    icon: Eye,
    title: "Always Visible",
    description: "Lives in your menu bar for instant cost visibility without switching contexts",
    color: "primary"
  },
  {
    icon: BarChart3,
    title: "Visual Histograms",
    description: "14-day spending histograms per service with red/green coloring vs last month",
    color: "accent"
  },
  {
    icon: TrendingDown,
    title: "Smart Projections",
    description: "Month-end spending projection and percentage comparison to last month",
    color: "tertiary"
  },
  {
    icon: Users,
    title: "Multi-Profile Support",
    description: "Switch between multiple AWS accounts with smart error handling",
    color: "secondary"
  },
  {
    icon: Bell,
    title: "Budget Alerts",
    description: "Get notified before you exceed your monthly spending limits",
    color: "accent"
  },
  {
    icon: Zap,
    title: "Intelligent Refresh",
    description: "Adjusts polling frequency based on your spending patterns to minimize API calls",
    color: "primary"
  },
  {
    icon: Lock,
    title: "Privacy First",
    description: "Zero data collection. No external servers. Your AWS data never leaves your Mac.",
    color: "secondary"
  }
]

const Features = () => {
  return (
    <section id="features" className="features">
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="section-header"
        >
          <h2>Features That <span className="text-gradient">Matter</span></h2>
          <p>Everything you need to keep AWS costs under control, nothing you don't</p>
        </motion.div>
        
        <div className="features-grid">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              viewport={{ once: true }}
              className={`feature-card card card-brutal card-${feature.color}`}
            >
              <div className="feature-icon">
                <feature.icon size={32} />
              </div>
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
            </motion.div>
          ))}
        </div>
        
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="privacy-highlight"
        >
          <div className="privacy-content">
            <div className="privacy-icon">
              <Lock size={48} />
            </div>
            <div className="privacy-text">
              <h3>Your Data Stays Yours</h3>
              <p>
                Built from the ground up with privacy as a core principle. Unlike other monitoring tools,
                AWS Cost Monitor operates entirely on your local machine with zero data collection.
              </p>
              <div className="privacy-points">
                <div className="privacy-point">
                  <Shield size={20} />
                  <span>No external servers or cloud services</span>
                </div>
                <div className="privacy-point">
                  <Shield size={20} />
                  <span>No telemetry, analytics, or tracking</span>
                </div>
                <div className="privacy-point">
                  <Shield size={20} />
                  <span>Your AWS credentials never leave your Mac</span>
                </div>
                <div className="privacy-point">
                  <Shield size={20} />
                  <span>Open source and auditable</span>
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="feature-highlight"
        >
          <div className="highlight-content">
            <div className="highlight-text">
              <h3>Enterprise Features, Personal Simplicity</h3>
              <p>
                AWSCostMonitor brings enterprise-grade cost monitoring to individual developers 
                and small teams. No complex setup, no monthly fees, no data leaving your machine.
              </p>
              <ul className="feature-list">
                <li>✓ Service-by-service cost breakdown</li>
                <li>✓ Monthly spending forecasts</li>
                <li>✓ Historical data tracking</li>
                <li>✓ Export to CSV/JSON</li>
                <li>✓ Anomaly detection</li>
                <li>✓ API rate limiting protection</li>
              </ul>
            </div>
            <div className="highlight-visual">
              <div className="cost-chart">
                <div className="chart-bar" style={{ height: '60%', background: 'var(--color-secondary)' }}>
                  <span>Jan</span>
                </div>
                <div className="chart-bar" style={{ height: '80%', background: 'var(--color-secondary)' }}>
                  <span>Feb</span>
                </div>
                <div className="chart-bar" style={{ height: '40%', background: 'var(--color-primary)' }}>
                  <span>Mar</span>
                </div>
                <div className="chart-bar" style={{ height: '30%', background: 'var(--color-tertiary)' }}>
                  <span>Apr</span>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
      
      <style jsx>{`
        .features {
          background: var(--color-white);
          position: relative;
        }
        
        .section-header {
          text-align: center;
          margin-bottom: var(--space-3xl);
        }
        
        .section-header h2 {
          margin-bottom: var(--space-md);
        }
        
        .section-header p {
          font-size: 1.25rem;
          opacity: 0.8;
        }
        
        .features-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: var(--space-xl);
          margin-bottom: var(--space-3xl);
        }
        
        .feature-card {
          text-align: center;
          cursor: default;
        }
        
        .feature-card h3 {
          margin: var(--space-md) 0;
          font-size: 1.25rem;
        }
        
        .feature-card p {
          opacity: 0.9;
        }
        
        .feature-icon {
          width: 64px;
          height: 64px;
          margin: 0 auto;
          display: flex;
          align-items: center;
          justify-content: center;
          background: rgba(255, 255, 255, 0.2);
          border-radius: var(--radius-lg);
        }

        .privacy-highlight {
          background: linear-gradient(135deg, var(--color-dark), var(--color-primary));
          color: white;
          border-radius: var(--radius-xl);
          padding: var(--space-2xl);
          margin-bottom: var(--space-2xl);
          box-shadow: var(--shadow-2xl);
        }

        .privacy-content {
          display: flex;
          align-items: center;
          gap: var(--space-2xl);
        }

        .privacy-icon {
          flex-shrink: 0;
          width: 96px;
          height: 96px;
          background: rgba(255, 255, 255, 0.1);
          border-radius: var(--radius-lg);
          display: flex;
          align-items: center;
          justify-content: center;
          color: var(--color-accent);
        }

        .privacy-text h3 {
          font-size: 2rem;
          margin-bottom: var(--space-md);
          color: white;
        }

        .privacy-text p {
          font-size: 1.1rem;
          margin-bottom: var(--space-lg);
          opacity: 0.9;
        }

        .privacy-points {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: var(--space-md);
        }

        .privacy-point {
          display: flex;
          align-items: center;
          gap: var(--space-sm);
          font-size: 1rem;
        }

        .privacy-point svg {
          color: var(--color-accent);
          flex-shrink: 0;
        }
        
        .feature-highlight {
          background: var(--color-light);
          border-radius: var(--radius-xl);
          padding: var(--space-2xl);
          box-shadow: var(--shadow-2xl);
        }
        
        .highlight-content {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: var(--space-2xl);
          align-items: center;
        }
        
        .highlight-text h3 {
          margin-bottom: var(--space-md);
        }
        
        .feature-list {
          list-style: none;
          margin-top: var(--space-lg);
        }
        
        .feature-list li {
          padding: var(--space-xs) 0;
          font-size: 1rem;
        }
        
        .cost-chart {
          display: flex;
          align-items: flex-end;
          justify-content: space-around;
          height: 200px;
          padding: var(--space-md);
          background: white;
          border-radius: var(--radius-lg);
          box-shadow: var(--shadow-md);
        }
        
        .chart-bar {
          width: 60px;
          border-radius: var(--radius-sm) var(--radius-sm) 0 0;
          position: relative;
          transition: all 0.3s ease;
        }
        
        .chart-bar:hover {
          transform: translateY(-5px);
        }
        
        .chart-bar span {
          position: absolute;
          bottom: -25px;
          left: 50%;
          transform: translateX(-50%);
          font-size: 0.875rem;
          font-weight: 600;
        }
        
        @media (max-width: 768px) {
          .privacy-content {
            flex-direction: column;
            text-align: center;
          }

          .privacy-text h3 {
            font-size: 1.5rem;
          }

          .privacy-points {
            grid-template-columns: 1fr;
          }

          .highlight-content {
            grid-template-columns: 1fr;
          }
          
          .cost-chart {
            margin-top: var(--space-lg);
          }
        }
      `}</style>
    </section>
  )
}

export default Features