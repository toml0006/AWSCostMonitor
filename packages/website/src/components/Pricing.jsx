import { motion } from 'framer-motion'
import { Check, Sparkles, Heart, Coffee } from 'lucide-react'

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
          <h2>Simple <span className="text-gradient">Pricing</span></h2>
          <p>Free to start, Pro features for teams. No subscriptions.</p>
        </motion.div>
        
        <div className="pricing-grid">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="pricing-card"
          >
            <div className="price-badge">
              <Sparkles size={24} />
              <span>FREE</span>
            </div>
            
            <div className="price-amount">
              <span className="currency">$</span>
              <span className="number">0</span>
              <span className="period">/forever</span>
            </div>
            
            <p className="price-description">
              Perfect for individual developers and personal use
            </p>
            
            <div className="features-list">
              <div className="feature">
                <Check size={20} />
                <span>Single AWS profile</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Real-time cost monitoring</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Calendar view</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Interactive charts</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Manual refresh</span>
              </div>
              <div className="feature">
                <Check size={20} />
                <span>Basic alerts</span>
              </div>
            </div>
            
            <a href="https://github.com/toml0006/AWSCostMonitor/releases" 
               className="btn btn-outline price-cta">
              Download Free
            </a>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            viewport={{ once: true }}
            className="pricing-card pricing-card-pro"
          >
            <div className="price-badge price-badge-pro">
              <Sparkles size={24} />
              <span>PRO</span>
            </div>
            
            <div className="price-amount">
              <span className="currency">$</span>
              <span className="number">3.99</span>
              <span className="period">/one-time</span>
            </div>
            
            <p className="price-description">
              For teams and power users. 3-day free trial included.
            </p>
            
            <div className="features-list">
              <div className="feature">
                <Check size={20} />
                <span>Everything in Free</span>
              </div>
              <div className="feature feature-pro">
                <Check size={20} />
                <span>Unlimited AWS profiles</span>
              </div>
              <div className="feature feature-pro">
                <Check size={20} />
                <span>Team cache sharing via S3</span>
              </div>
              <div className="feature feature-pro">
                <Check size={20} />
                <span>Advanced forecasting</span>
              </div>
              <div className="feature feature-pro">
                <Check size={20} />
                <span>Smart refresh rates</span>
              </div>
              <div className="feature feature-pro">
                <Check size={20} />
                <span>Priority support</span>
              </div>
            </div>
            
            <a href="https://github.com/toml0006/AWSCostMonitor/releases" 
               className="btn btn-primary price-cta">
              Try Free for 3 Days
            </a>
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