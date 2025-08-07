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
      
      <style>{`
        .pricing {
          background: var(--color-white);
        }
        
        .section-header {
          text-align: center;
          margin-bottom: var(--space-3xl);
        }
        
        .section-header h2 {
          margin-bottom: var(--space-md);
        }
        
        .pricing-card {
          max-width: 500px;
          margin: 0 auto var(--space-3xl);
          background: linear-gradient(135deg, var(--color-light) 0%, var(--color-white) 100%);
          border-radius: var(--radius-xl);
          padding: var(--space-2xl);
          box-shadow: var(--shadow-2xl);
          text-align: center;
          position: relative;
          border: 3px solid var(--color-primary);
        }
        
        .price-badge {
          position: absolute;
          top: -20px;
          left: 50%;
          transform: translateX(-50%);
          background: var(--color-primary);
          color: var(--color-white);
          padding: var(--space-xs) var(--space-md);
          border-radius: var(--radius-full);
          display: flex;
          align-items: center;
          gap: var(--space-xs);
          font-weight: 700;
          font-size: 0.875rem;
        }
        
        .price-amount {
          margin: var(--space-lg) 0;
          display: flex;
          align-items: baseline;
          justify-content: center;
          gap: 0.25rem;
        }
        
        .price-amount .currency {
          font-size: 2rem;
          color: var(--color-primary);
        }
        
        .price-amount .number {
          font-size: 4rem;
          font-weight: 700;
          font-family: var(--font-primary);
        }
        
        .price-amount .period {
          font-size: 1.25rem;
          opacity: 0.7;
        }
        
        .price-description {
          font-size: 1.125rem;
          margin-bottom: var(--space-xl);
          opacity: 0.8;
        }
        
        .features-list {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: var(--space-md);
          margin-bottom: var(--space-xl);
          text-align: left;
        }
        
        .feature {
          display: flex;
          align-items: center;
          gap: var(--space-sm);
        }
        
        .feature svg {
          color: var(--color-secondary);
          flex-shrink: 0;
        }
        
        .price-cta {
          width: 100%;
          justify-content: center;
        }
        
        .support-section {
          text-align: center;
          padding: var(--space-2xl);
          background: var(--color-light);
          border-radius: var(--radius-xl);
        }
        
        .support-section h3 {
          margin: var(--space-md) 0;
        }
        
        .support-section p {
          max-width: 600px;
          margin: 0 auto var(--space-lg);
        }
        
        .support-actions {
          display: flex;
          gap: var(--space-md);
          justify-content: center;
          flex-wrap: wrap;
        }
        
        @media (max-width: 768px) {
          .features-list {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </section>
  )
}

export default Pricing