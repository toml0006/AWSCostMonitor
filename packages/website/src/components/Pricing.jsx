import { motion } from 'framer-motion'
import { Check, Sparkles, Heart, Coffee, Users, Github, Apple } from 'lucide-react'

const Pricing = () => {
  return (
    <section id="pricing" className="pricing">
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="section-header"
        >
          <h2>Choose Your <span className="text-gradient">Edition</span></h2>
          <p>Free forever on GitHub, or support development through the App Store</p>
        </motion.div>
        
        <div className="pricing-cards-grid">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="pricing-card"
          >
            <div className="price-badge">
              <Github size={24} />
              <span>OPEN SOURCE</span>
            </div>
            
            <div className="price-amount">
              <span className="currency">$</span>
              <span className="number">0</span>
              <span className="period">/forever</span>
            </div>
            
            <p className="price-description">
              Full-featured, open source, and free forever. Build it yourself, customize it, make it yours.
            </p>
            
            <div className="features-list">
              <div className="feature">
                <Check size={20} />
                <span>All core features</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Unlimited AWS profiles</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Real-time monitoring</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Calendar & charts</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Budget alerts</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Export data</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Community support</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Forever updates</span>
              </div>
            </div>
            
            <a href="https://github.com/toml0006/AWSCostMonitor/releases" 
               className="btn btn-outline price-cta">
              <Github size={18} />
              Download from GitHub
            </a>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            viewport={{ once: true }}
            className="pricing-card pricing-card-featured"
          >
            <div className="price-badge price-badge-featured">
              <Users size={24} />
              <span>TEAM EDITION</span>
            </div>
            
            <div className="price-amount">
              <span className="currency">$</span>
              <span className="number">3.99</span>
              <span className="period">/once</span>
            </div>
            
            <p className="price-description">
              <strong>100% optional!</strong> Same app + Team Cache. Only charging to offset Apple's developer fees & Claude AI costs. 
              <span className="no-pressure">Seriously, no pressure! 💙</span>
            </p>
            
            <div className="features-list">
              <div className="feature">
                <Check size={20} />
                <span><strong>Everything from GitHub</strong></span>
              </div>
              <div className="feature feature-highlight">
                <Sparkles size={20} />
                <span><strong>Team Cache via S3</strong></span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Automatic updates</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Mac App Store convenience</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Signed & notarized</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Support development</span>
              </div>
              <div className="feature">
                <Heart size={20} color="var(--color-primary)" />
                <span>My eternal gratitude</span>
              </div>
              <div className="feature">
                <Coffee size={20} />
                <span>Funds my coffee habit</span>
              </div>
            </div>
            
            <button className="btn btn-primary price-cta" disabled>
              <Apple size={18} />
              Coming Soon
            </button>
            
            <p className="support-note">
              Supporting indie development, one coffee at a time ☕
            </p>
          </motion.div>
        </div>
        
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          viewport={{ once: true }}
          className="support-section"
        >
          <Heart size={32} color="var(--color-primary)" />
          <h3>Want to Support?</h3>
          <p>
            If AWSCostMonitor saves you money, consider starring the repo on GitHub 
            or sharing it with your team. Your support helps keep the project alive!
          </p>
          <div className="support-actions">
            <a href="https://github.com/toml0006/AWSCostMonitor" 
               className="btn btn-outline">
              ⭐ Star on GitHub
            </a>
            <a href="https://www.linkedin.com/sharing/share-offsite/?url=https://toml0006.github.io/AWSCostMonitor/" 
               className="btn btn-outline">
              Share on LinkedIn
            </a>
            <a href="https://buymeacoffee.com/jacksontomlinson" 
               className="btn btn-primary">
              <Coffee size={18} />
              Buy Me a Coffee
            </a>
          </div>
          <p className="coffee-note">
            ☕ Help me pay my own AWS bill while building tools to help you pay yours! 
            Your support keeps the servers running and the features coming.
          </p>
        </motion.div>
      </div>
      
    </section>
  )
}

export default Pricing