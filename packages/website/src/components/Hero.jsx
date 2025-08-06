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
      
      <style jsx>{`
        .hero {
          min-height: 100vh;
          display: flex;
          align-items: center;
          position: relative;
          background: linear-gradient(180deg, var(--color-light) 0%, rgba(255, 239, 213, 0.5) 100%);
          overflow: hidden;
        }
        
        .hero::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background-image: radial-gradient(circle at 20% 50%, var(--color-primary) 0%, transparent 50%),
                            radial-gradient(circle at 80% 80%, var(--color-secondary) 0%, transparent 50%),
                            radial-gradient(circle at 40% 20%, var(--color-tertiary) 0%, transparent 50%);
          opacity: 0.1;
          z-index: 0;
        }
        
        .hero-content {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: var(--space-3xl);
          align-items: center;
          position: relative;
          z-index: 1;
        }
        
        .hero-badge {
          display: inline-flex;
          align-items: center;
          gap: var(--space-sm);
          margin-bottom: var(--space-lg);
        }
        
        .badge-primary {
          background-color: var(--color-primary);
          color: var(--color-white);
          padding: 0.25rem 0.75rem;
          border-radius: var(--radius-full);
          font-size: 0.875rem;
          font-weight: 700;
        }
        
        .hero-title {
          margin-bottom: var(--space-lg);
        }
        
        .hero-description {
          font-size: 1.25rem;
          margin-bottom: var(--space-xl);
          color: var(--color-dark);
          opacity: 0.8;
        }
        
        .hero-cta {
          display: flex;
          gap: var(--space-md);
          margin-bottom: var(--space-xl);
        }
        
        .hero-stats {
          display: flex;
          gap: var(--space-xl);
        }
        
        .stat {
          display: flex;
          flex-direction: column;
        }
        
        .stat-number {
          font-size: 1.5rem;
          font-weight: 700;
          color: var(--color-primary);
        }
        
        .stat-label {
          font-size: 0.875rem;
          color: var(--color-dark);
          opacity: 0.6;
        }
        
        .app-mockup {
          position: relative;
          max-width: 400px;
          margin: 0 auto;
        }
        
        .menu-bar-mockup {
          background: rgba(255, 255, 255, 0.95);
          backdrop-filter: blur(10px);
          border-radius: var(--radius-md);
          padding: 0.5rem 1rem;
          box-shadow: var(--shadow-xl);
          margin-bottom: 1rem;
        }
        
        .menu-bar-item {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          font-family: 'SF Pro Display', -apple-system, system-ui, sans-serif;
          font-weight: 500;
        }
        
        .trend-indicator {
          margin-left: auto;
        }
        
        .trend-down {
          color: var(--color-secondary);
        }
        
        .dropdown-mockup {
          background: white;
          border-radius: var(--radius-lg);
          padding: var(--space-md);
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
        }
        
        .dropdown-header {
          font-weight: 700;
          margin-bottom: var(--space-sm);
        }
        
        .dropdown-profile {
          background: var(--color-accent);
          padding: 0.5rem;
          border-radius: var(--radius-md);
          margin-bottom: var(--space-md);
          text-align: center;
        }
        
        .stat-row {
          display: flex;
          justify-content: space-between;
          padding: 0.5rem 0;
          border-bottom: 1px solid rgba(0, 0, 0, 0.05);
        }
        
        .stat-row.cached {
          border: none;
          opacity: 0.6;
          font-size: 0.875rem;
        }
        
        .stat-value {
          font-weight: 600;
        }
        
        @media (max-width: 768px) {
          .hero-content {
            grid-template-columns: 1fr;
            text-align: center;
          }
          
          .hero-cta {
            flex-direction: column;
            align-items: center;
          }
          
          .hero-stats {
            justify-content: center;
          }
        }
      `}</style>
    </section>
  )
}

export default Hero