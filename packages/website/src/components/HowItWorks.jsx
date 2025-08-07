import { motion } from 'framer-motion'
import { Download, Settings, Eye, Zap } from 'lucide-react'

const steps = [
  {
    icon: Download,
    number: "01",
    title: "Download & Install",
    description: "Download the app and drag it to your Applications folder. That's it!"
  },
  {
    icon: Settings,
    number: "02",
    title: "Select AWS Profile",
    description: "Choose from your existing AWS profiles in ~/.aws/config"
  },
  {
    icon: Eye,
    number: "03",
    title: "Watch Your Costs",
    description: "See real-time spending in your menu bar, updated intelligently"
  },
  {
    icon: Zap,
    number: "04",
    title: "Stay Alert",
    description: "Get notified when spending exceeds your configured thresholds"
  }
]

const HowItWorks = () => {
  return (
    <section id="how-it-works" className="how-it-works">
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="section-header"
        >
          <h2>Get Started in <span className="text-gradient">60 Seconds</span></h2>
          <p>No account creation. No API keys. No configuration files.</p>
        </motion.div>
        
        <div className="steps-container">
          {steps.map((step, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, x: -20 }}
              whileInView={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              viewport={{ once: true }}
              className="step"
            >
              <div className="step-number">{step.number}</div>
              <div className="step-content">
                <div className="step-icon">
                  <step.icon size={32} />
                </div>
                <h3>{step.title}</h3>
                <p>{step.description}</p>
              </div>
              {index < steps.length - 1 && <div className="step-connector" />}
            </motion.div>
          ))}
        </div>
        
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="requirements"
        >
          <h3>System Requirements</h3>
          <div className="requirements-grid">
            <div className="requirement-item">
              <strong>macOS</strong>
              <span>13.0 or later</span>
            </div>
            <div className="requirement-item">
              <strong>AWS CLI</strong>
              <span>Configured profiles</span>
            </div>
            <div className="requirement-item">
              <strong>Permissions</strong>
              <span>Cost Explorer read-only</span>
            </div>
            <div className="requirement-item">
              <strong>Storage</strong>
              <span>&lt; 50MB</span>
            </div>
          </div>
        </motion.div>
      </div>
      
      <style>{`
        .how-it-works {
          background: linear-gradient(135deg, var(--color-light) 0%, var(--color-white) 100%);
          position: relative;
        }
        
        .section-header {
          text-align: center;
          margin-bottom: var(--space-3xl);
        }
        
        .section-header h2 {
          margin-bottom: var(--space-md);
        }
        
        .steps-container {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: var(--space-xl);
          margin-bottom: var(--space-3xl);
          position: relative;
        }
        
        .step {
          position: relative;
          text-align: center;
        }
        
        .step-number {
          position: absolute;
          top: -20px;
          left: 50%;
          transform: translateX(-50%);
          font-size: 3rem;
          font-weight: 700;
          color: var(--color-primary);
          opacity: 0.2;
          font-family: var(--font-primary);
        }
        
        .step-content {
          background: var(--color-white);
          padding: var(--space-xl);
          border-radius: var(--radius-lg);
          box-shadow: var(--shadow-lg);
          position: relative;
          z-index: 1;
        }
        
        .step-icon {
          width: 64px;
          height: 64px;
          margin: 0 auto var(--space-md);
          display: flex;
          align-items: center;
          justify-content: center;
          background: var(--color-secondary);
          color: var(--color-white);
          border-radius: var(--radius-lg);
        }
        
        .step h3 {
          margin-bottom: var(--space-sm);
          font-size: 1.25rem;
        }
        
        .step p {
          opacity: 0.8;
        }
        
        .step-connector {
          position: absolute;
          top: 50%;
          right: -40px;
          width: 40px;
          height: 2px;
          background: var(--color-primary);
          opacity: 0.3;
        }
        
        .requirements {
          background: var(--color-white);
          padding: var(--space-2xl);
          border-radius: var(--radius-xl);
          box-shadow: var(--shadow-xl);
          text-align: center;
        }
        
        .requirements h3 {
          margin-bottom: var(--space-lg);
        }
        
        .requirements-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
          gap: var(--space-lg);
        }
        
        .requirement-item {
          display: flex;
          flex-direction: column;
          padding: var(--space-md);
          background: var(--color-light);
          border-radius: var(--radius-md);
        }
        
        .requirement-item strong {
          color: var(--color-primary);
          margin-bottom: var(--space-xs);
        }
        
        .requirement-item span {
          font-size: 0.875rem;
          opacity: 0.7;
        }
        
        @media (max-width: 768px) {
          .step-connector {
            display: none;
          }
        }
      `}</style>
    </section>
  )
}

export default HowItWorks