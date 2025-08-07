import { motion } from 'framer-motion'
import { Check, Sparkles, Heart } from 'lucide-react'

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
          <p>Actually, there's no pricing. It's completely free.</p>
        </motion.div>
        
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="pricing-card"
        >
          <div className="price-badge">
            <Sparkles size={24} />
            <span>FOREVER FREE</span>
          </div>
          
          <div className="price-amount">
            <span className="currency">$</span>
            <span className="number">0</span>
            <span className="period">/forever</span>
          </div>
          
          <p className="price-description">
            Open source and free forever. No premium tiers, no upsells, no catch.
          </p>
          
          <div className="features-list">
            <div className="feature">
              <Check size={20} />
              <span>Unlimited AWS profiles</span>
            </div>
            <div className="feature">
              <Check size={20} />
              <span>Real-time cost monitoring</span>
            </div>
            <div className="feature">
              <Check size={20} />
              <span>Smart refresh rates</span>
            </div>
            <div className="feature">
              <Check size={20} />
              <span>Budget alerts</span>
            </div>
            <div className="feature">
              <Check size={20} />
              <span>Service breakdown</span>
            </div>
            <div className="feature">
              <Check size={20} />
              <span>Historical tracking</span>
            </div>
            <div className="feature">
              <Check size={20} />
              <span>Export to CSV/JSON</span>
            </div>
            <div className="feature">
              <Check size={20} />
              <span>Forever updates</span>
            </div>
          </div>
          
          <a href="https://github.com/yourusername/awscostmonitor/releases" 
             className="btn btn-primary price-cta">
            Download Now
          </a>
        </motion.div>
        
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
            <a href="https://github.com/yourusername/awscostmonitor" 
               className="btn btn-outline">
              ⭐ Star on GitHub
            </a>
            <a href="https://twitter.com/intent/tweet?text=Check%20out%20AWSCostMonitor" 
               className="btn btn-outline">
              Share on Twitter
            </a>
          </div>
        </motion.div>
      </div>
      
    </section>
  )
}

export default Pricing