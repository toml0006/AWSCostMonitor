import { motion } from 'framer-motion'
import { DollarSign, Download, Github, ArrowRight, Apple } from 'lucide-react'

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
              <span className="badge-primary">v1.5</span>
              <span>Ledger — a refreshed visual identity</span>
            </div>

            <h1 className="hero-title">
              Your AWS Spend,
              <span className="text-gradient"> in the Menu Bar</span>
            </h1>

            <p className="hero-description">
              AWSCostMonitor by MiddleOut pins your month-to-date spend to the macOS menu bar
              with an optional sparkline pill. Track multiple AWS profiles, tune four appearance axes,
              and stay ahead of bill shock — all with zero accounts and zero telemetry.
            </p>
            
            <div className="hero-cta">
              <a href="https://apps.apple.com/app/id6749865679"
                 className="btn btn-primary btn-memphis">
                <Apple size={20} />
                Get on the App Store — $3.99
              </a>
              <a href="https://github.com/toml0006/AWSCostMonitor"
                 className="btn btn-outline btn-memphis">
                <Github size={20} />
                Free on GitHub (OSS)
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
            <div className="hero-screenshot-frame">
              <div className="frame-dots">
                <span></span>
                <span></span>
                <span></span>
              </div>
              <div className="hero-screenshot-image">
                <img
                  src="/screenshots/main-interface.webp"
                  alt="AWSCostMonitor menu bar dashboard showing MTD cost, forecast, and top services"
                  className="hero-screenshot"
                  width="1586"
                  height="992"
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