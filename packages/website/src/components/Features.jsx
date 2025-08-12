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
  Lock,
  Calendar,
  PieChart
} from 'lucide-react'

const features = [
  {
    icon: Calendar,
    title: 'Calendar View',
    description: 'Beautiful monthly calendar showing daily spending patterns with color-coded intensity',
    color: 'primary',
    badge: 'v1.2.0'
  },
  {
    icon: PieChart,
    title: 'Interactive Charts',
    description: 'Professional donut charts with hover effects showing service cost breakdowns',
    color: 'accent',
    badge: 'v1.2.0'
  },
  {
    icon: Eye,
    title: 'Always Visible',
    description: 'Lives in your menu bar for instant cost visibility without switching contexts',
    color: 'tertiary'
  },
  {
    icon: BarChart3,
    title: 'Visual Histograms',
    description: '14-day spending histograms per service with red/green coloring vs last month',
    color: 'secondary'
  },
  {
    icon: TrendingDown,
    title: 'Smart Projections',
    description: 'Month-end spending projection and percentage comparison to last month',
    color: 'primary'
  },
  {
    icon: Users,
    title: 'Multi-Profile Support',
    description: 'Switch between multiple AWS accounts with smart error handling',
    color: 'accent'
  },
  {
    icon: Bell,
    title: 'Budget Alerts',
    description: 'Get notified before you exceed your monthly spending limits',
    color: 'tertiary'
  },
  {
    icon: Zap,
    title: 'Intelligent Refresh',
    description: 'Adjusts polling frequency based on your spending patterns to minimize API calls',
    color: 'secondary'
  },
  {
    icon: Lock,
    title: 'Privacy First',
    description: 'Zero data collection. No external servers. Your AWS data never leaves your Mac.',
    color: 'primary'
  }
]

const Features = () => {
  return (
    <section id="features" className="features pattern-dots">
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
              className={`feature-card card card-brutal card-memphis card-${feature.color}`}
            >
              <div className="feature-icon">
                <feature.icon size={32} />
                {feature.badge && (
                  <span className="feature-badge">
                    {feature.badge}
                  </span>
                )}
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
                AWSCostMonitor brings enterprise-grade cost monitoring to individual developers and
                small teams. No complex setup, no monthly fees, no data leaving your machine.
              </p>
              <ul className="feature-list">
                <li>✓ Calendar view with daily spending patterns</li>
                <li>✓ Interactive donut charts with hover effects</li>
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
      
    </section>
  )
}

export default Features