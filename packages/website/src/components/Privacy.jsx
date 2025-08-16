import { useState } from 'react'
import { Shield, Lock, Eye, Server, Cloud, Database, Key, UserX, DollarSign } from 'lucide-react'
import { motion } from 'framer-motion'
import Navigation from './Navigation'
import Footer from './Footer'
import GeometricShapes from './GeometricShapes'
import MemphisPatterns from './MemphisPatterns'

function Privacy() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  return (
    <div className="app">
      <GeometricShapes />
      <MemphisPatterns />
      
      <Navigation isMenuOpen={isMenuOpen} setIsMenuOpen={setIsMenuOpen} />

      {/* Hero Section */}
      <section className="hero memphis-decoration">
        <div className="memphis-hero-bg" />
        <div className="memphis-grid-overlay" />
        <div className="container">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="hero-text" style={{ maxWidth: '800px', margin: '0 auto', textAlign: 'center' }}
          >
            <div className="hero-badge">
              <span className="badge-primary">PRIVACY FIRST</span>
              <span>Your data stays yours</span>
            </div>
            
            <h1 className="hero-title">
              Privacy
              <span className="text-gradient"> Policy</span>
            </h1>
            
            <p className="hero-description">
              Your privacy is our priority. AWSCostMonitor is designed from the ground up 
              to protect your data. Here's our commitment to keeping your information secure.
            </p>
            
            <div className="hero-stats">
              <div className="stat">
                <span className="stat-number">Zero</span>
                <span className="stat-label">Data Collection</span>
              </div>
              <div className="stat">
                <span className="stat-number">100%</span>
                <span className="stat-label">Local Processing</span>
              </div>
              <div className="stat">
                <span className="stat-number">Open</span>
                <span className="stat-label">Source Code</span>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Privacy Highlights */}
      <section className="features pattern-dots" style={{ paddingTop: '60px', paddingBottom: '60px' }}>
        <div className="container">
          <div className="features-grid" style={{ gridTemplateColumns: 'repeat(3, 1fr)' }}>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="feature-card card card-brutal card-memphis card-primary"
            >
              <div className="feature-icon">
                <UserX size={32} />
              </div>
              <h3>No Data Collection</h3>
              <p>We don't collect, store, or transmit any of your personal or usage data</p>
            </motion.div>
            
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="feature-card card card-brutal card-memphis card-secondary"
            >
              <div className="feature-icon">
                <Database size={32} />
              </div>
              <h3>100% Local</h3>
              <p>Everything runs on your Mac - no external servers or cloud services</p>
            </motion.div>
            
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="feature-card card card-brutal card-memphis card-tertiary"
            >
              <div className="feature-icon">
                <Key size={32} />
              </div>
              <h3>Your AWS, Your Control</h3>
              <p>Direct connection to AWS using your credentials - we never see them</p>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Privacy Content */}
      <section className="privacy-content pattern-squiggle">
        <div className="container">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="section-header"
            style={{ textAlign: 'center', marginBottom: '3rem' }}
          >
            <h2>How We Protect <span className="text-gradient">Your Privacy</span></h2>
            <p>Everything you need to know about how AWSCostMonitor handles your data</p>
          </motion.div>
          
          <div className="privacy-sections">
            
            {/* How It Works */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="card card-brutal card-memphis"
            >
              <div className="section-header">
                <Lock size={24} />
                <h2>How AWSCostMonitor Works</h2>
              </div>
              
              <div className="privacy-subsection">
                <h3>Local-Only Architecture</h3>
                <ul className="privacy-list">
                  <li><strong>No telemetry</strong> - We don't track usage or collect analytics</li>
                  <li><strong>No phone home</strong> - The app never contacts our servers (we don't have any!)</li>
                  <li><strong>No accounts</strong> - No registration or sign-up required</li>
                  <li><strong>No ads</strong> - No advertising or tracking mechanisms</li>
                </ul>
              </div>

              <div className="privacy-subsection">
                <h3>AWS Credentials Management</h3>
                <ul className="privacy-list">
                  <li>Read from your existing AWS CLI configuration (~/.aws/config)</li>
                  <li>Never transmitted to us or any third party</li>
                  <li>Used only for direct API calls from your Mac to AWS</li>
                  <li>Managed by macOS's secure system configuration</li>
                </ul>
              </div>

              <div className="privacy-subsection">
                <h3>Data Flow</h3>
                <div className="code-block card card-brutal" style={{ background: 'var(--color-secondary)', color: 'white', fontWeight: 'bold' }}>
                  Your Mac → AWS Cost Explorer API → Cost Data → Display in Menu Bar
                </div>
                <p className="privacy-note">That's it. No detours. No middleman. Just direct, secure communication.</p>
              </div>
            </motion.div>

            {/* What We Don't Do */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              className="card card-brutal card-memphis"
            >
              <div className="section-header">
                <Server size={24} />
                <h2>What We Don't Do</h2>
              </div>
              
              <div className="privacy-grid">
                <ul className="privacy-list no-list">
                  <li>❌ No user tracking</li>
                  <li>❌ No usage analytics</li>
                  <li>❌ No error reporting to us</li>
                  <li>❌ No crash analytics</li>
                </ul>
                <ul className="privacy-list no-list">
                  <li>❌ No behavioral data</li>
                  <li>❌ No marketing data</li>
                  <li>❌ No data selling</li>
                  <li>❌ No third-party sharing</li>
                </ul>
              </div>
            </motion.div>

            {/* Team Cache Feature */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6 }}
              className="card card-brutal card-memphis"
            >
              <div className="section-header">
                <Cloud size={24} />
                <h2>Optional Team Cache Feature</h2>
              </div>
              
              <p>If you choose to enable Team Cache:</p>
              <ul className="privacy-list">
                <li>Data is stored in <strong>your own AWS S3 bucket</strong></li>
                <li>You specify the bucket and control access</li>
                <li>Only team members with access to that bucket can share data</li>
                <li>We have no visibility into this data</li>
                <li>Everything stays within your AWS infrastructure</li>
              </ul>
            </motion.div>

            {/* Open Source */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.7 }}
              className="card card-brutal card-memphis"
            >
              <div className="section-header">
                <Eye size={24} />
                <h2>Open Source Transparency</h2>
              </div>
              
              <p>AWSCostMonitor is open source. You can:</p>
              <ul className="privacy-list">
                <li>Review our code on <a href="https://github.com/toml0006/AWSCostMonitor" className="text-link">GitHub</a></li>
                <li>Verify our privacy claims</li>
                <li>Build it yourself from source</li>
                <li>Contribute improvements</li>
              </ul>
            </motion.div>

            {/* Privacy Promise */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.8 }}
              className="privacy-highlight card-gradient"
            >
              <h2>Privacy Promise</h2>
              <p className="promise-text">
                <strong>Your AWS cost data is yours alone.</strong><br />
                We can't see it, we don't want to see it, and we've built AWSCostMonitor to ensure it stays that way.
              </p>
              <div className="promise-reasons">
                <div className="reason">
                  <DollarSign size={20} />
                  <span>No venture capital = No pressure to monetize your data</span>
                </div>
                <div className="reason">
                  <Shield size={20} />
                  <span>No data collection = Nothing to leak or breach</span>
                </div>
                <div className="reason">
                  <Eye size={20} />
                  <span>Open source = Complete transparency</span>
                </div>
                <div className="reason">
                  <Database size={20} />
                  <span>Local only = Your data never leaves your Mac</span>
                </div>
              </div>
            </motion.div>

            {/* Contact Section */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.9 }}
              className="card card-brutal card-memphis"
              style={{ textAlign: 'center', padding: '2rem' }}
            >
              <h3 style={{ marginBottom: '1rem' }}>Questions about privacy?</h3>
              <p style={{ marginBottom: '1.5rem' }}>We're here to help:</p>
              <div className="hero-cta" style={{ justifyContent: 'center' }}>
                <a href="https://github.com/toml0006/AWSCostMonitor/issues" className="btn btn-outline btn-memphis">
                  Report an Issue
                </a>
                <a href="https://github.com/toml0006/AWSCostMonitor" className="btn btn-primary btn-memphis">
                  View Source Code
                </a>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      <Footer />

      <style jsx>{`
        .privacy-content {
          padding: 60px 0 100px;
          background: var(--bg-secondary);
          display: flex;
          justify-content: center;
        }

        .privacy-sections {
          max-width: 900px;
          width: 100%;
          margin: 0 auto;
          padding: 0 20px;
        }

        .privacy-sections .card {
          margin-bottom: 2rem;
          padding: 2rem;
        }

        .section-header {
          display: flex;
          align-items: center;
          gap: 1rem;
          margin-bottom: 1.5rem;
        }

        .section-header h2 {
          font-size: 1.75rem;
          margin: 0;
        }

        .privacy-subsection {
          margin-top: 2rem;
        }

        .privacy-subsection h3 {
          font-size: 1.25rem;
          margin-bottom: 1rem;
          color: var(--text-primary);
        }

        .privacy-list {
          list-style: none;
          padding: 0;
          margin: 1rem 0;
        }

        .privacy-list li {
          padding: 0.5rem 0;
          line-height: 1.6;
        }

        .privacy-list.no-list li {
          padding: 0.25rem 0;
        }

        .privacy-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 2rem;
        }

        .privacy-note {
          margin-top: 0.5rem;
          opacity: 0.8;
          font-size: 0.95rem;
        }

        .privacy-highlight {
          background: linear-gradient(135deg, var(--color-primary), var(--color-secondary));
          color: white;
          padding: 3rem;
          border-radius: var(--radius-xl);
          text-align: center;
          margin: 3rem 0;
          box-shadow: 12px 12px 0 var(--color-black);
          border: 3px solid var(--color-black);
        }

        .promise-text {
          font-size: 1.25rem;
          line-height: 1.8;
          margin-bottom: 2rem;
        }

        .promise-reasons {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 1.5rem;
          margin-top: 2rem;
        }

        .reason {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          text-align: left;
        }

        .text-link {
          color: var(--color-primary);
          text-decoration: none;
          border-bottom: 2px solid transparent;
          transition: border-color 0.3s;
          font-weight: 600;
        }

        .text-link:hover {
          border-bottom-color: var(--color-primary);
        }

        @media (max-width: 768px) {
          .privacy-sections .card {
            padding: 1.5rem;
          }

          .privacy-highlight {
            padding: 2rem 1.5rem;
          }

          .promise-text {
            font-size: 1.1rem;
          }

          .features-grid {
            grid-template-columns: 1fr !important;
          }
        }
      `}</style>
    </div>
  )
}

export default Privacy