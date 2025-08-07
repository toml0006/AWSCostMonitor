import { motion } from 'framer-motion'
import { DollarSign, Download, Github, ArrowRight } from 'lucide-react'

const Hero = () => {
  return (
    <section className="hero">
      <div className="container">
        <div className="hero-content">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="hero-text"
          >
            <div className="hero-badge">
              <span className="badge-primary">NEW</span>
              <span>Never get surprised by AWS bills again</span>
            </div>
            
            <h1 className="hero-title">
              Keep Your AWS Costs
              <span className="text-gradient"> Under Control</span>
            </h1>
            
            <p className="hero-description">
              AWSCostMonitor lives in your macOS menu bar, providing real-time visibility 
              into your cloud spending. Track multiple AWS accounts, get smart alerts, 
              and prevent bill shock — all with zero setup complexity.
            </p>
            
            <div className="hero-cta">
              <a href="https://github.com/yourusername/awscostmonitor/releases" 
                 className="btn btn-primary">
                <Download size={20} />
                Download for macOS
              </a>
              <a href="https://github.com/yourusername/awscostmonitor" 
                 className="btn btn-outline">
                <Github size={20} />
                View on GitHub
              </a>
            </div>
            
            <div className="hero-stats">
              <div className="stat">
                <span className="stat-number">1 min</span>
                <span className="stat-label">Setup time</span>
              </div>
              <div className="stat">
                <span className="stat-number">$0</span>
                <span className="stat-label">Forever free</span>
              </div>
              <div className="stat">
                <span className="stat-number">100%</span>
                <span className="stat-label">Private & local</span>
              </div>
            </div>
          </motion.div>
          
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="hero-visual"
          >
            <div className="app-mockup">
              <div className="menu-bar-mockup">
                <div className="menu-bar-item">
                  <DollarSign size={16} />
                  <span>$66.19</span>
                  <span className="trend-indicator trend-down">↓</span>
                </div>
              </div>
              <div className="dropdown-mockup">
                <div className="dropdown-header">AWS MTD Spend</div>
                <div className="dropdown-profile">ecoengineers</div>
                <div className="dropdown-stats">
                  <div className="stat-row">
                    <span>Current Month (MTD)</span>
                    <span className="stat-value">66.19</span>
                  </div>
                  <div className="stat-row">
                    <span>Last Month</span>
                    <span className="stat-value">1272.23 <span className="trend-down">↓</span></span>
                  </div>
                  <div className="stat-row cached">
                    <span>Cached: 1 day, 1 hr</span>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
      
    </section>
  )
}

export default Hero