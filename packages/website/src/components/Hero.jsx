import { motion } from 'framer-motion'
import { DollarSign, Download, Github, ArrowRight } from 'lucide-react'

const Hero = () => {
  return (
    <section className="hero memphis-decoration">
      <div className="memphis-hero-bg" />
      <div className="memphis-grid-overlay" />
      <div className="container">
        <div className="hero-content">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="hero-text"
          >
            <div className="hero-badge">
              <span className="badge-primary">v1.3.0</span>
              <span>Pro features + Team collaboration</span>
            </div>
            
            <h1 className="hero-title">
              Keep Your AWS Costs
              <span className="text-gradient"> Under Control</span>
            </h1>
            
            <p className="hero-description">
              AWSCostMonitor by MiddleOut lives in your macOS menu bar, providing real-time visibility 
              into your cloud spending. Track multiple AWS accounts, get smart alerts, 
              and prevent bill shock — all with zero setup complexity.
            </p>
            
            <div className="hero-cta">
              <a href="https://github.com/toml0006/AWSCostMonitor/releases" 
                 className="btn btn-primary btn-memphis">
                <Download size={20} />
                Download for macOS
              </a>
              <a href="https://github.com/toml0006/AWSCostMonitor" 
                 className="btn btn-outline btn-memphis">
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
                <span className="stat-number">$3.99</span>
                <span className="stat-label">Pro upgrade</span>
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
            <div className="hero-screenshot-frame">
              <div className="frame-dots">
                <span></span>
                <span></span>
                <span></span>
              </div>
              <div className="hero-screenshot-image">
                <img 
                  src="/AWSCostMonitor/screenshots/main-interface.png" 
                  alt="AWSCostMonitor main interface showing menu bar cost display with MiddleOut profile"
                  className="hero-screenshot"
                  width="2000"
                  height="1125"
                  fetchPriority="high"
                />
              </div>
            </div>
          </motion.div>
        </div>
      </div>
      
    </section>
  )
}

export default Hero