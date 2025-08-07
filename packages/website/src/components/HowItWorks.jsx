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
      
    </section>
  )
}

export default HowItWorks