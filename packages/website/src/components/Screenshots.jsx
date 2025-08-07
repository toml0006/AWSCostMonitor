import { motion } from 'framer-motion'
import { useState } from 'react'

const screenshots = [
  {
    title: "Menu Bar Display",
    description: "Always visible cost tracking in your macOS menu bar with real-time updates",
    image: "/screenshots/placeholder.svg",
    features: ["Real-time cost display", "Profile switching", "Quick refresh"]
  },
  {
    title: "Main Interface",
    description: "Detailed cost breakdown with interactive charts and spending trends",
    image: "/screenshots/placeholder.svg",
    features: ["14-day cost history", "Service breakdown", "Forecast projections"]
  },
  {
    title: "Settings & Configuration",
    description: "Customize refresh rates, budgets, and display options to fit your workflow",
    image: "/screenshots/placeholder.svg",
    features: ["Per-profile budgets", "Smart refresh rates", "Display customization"]
  },
  {
    title: "Help & Documentation",
    description: "Built-in help system with keyboard shortcuts and troubleshooting guides",
    image: "/screenshots/placeholder.svg",
    features: ["Keyboard shortcuts", "API usage tracking", "Troubleshooting"]
  }
]

const Screenshots = () => {
  const [activeIndex, setActiveIndex] = useState(0)
  
  return (
    <section id="screenshots" className="screenshots pattern-squiggle">
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="section-header"
        >
          <h2>See It In <span className="text-gradient">Action</span></h2>
          <p>Clean, intuitive interface that stays out of your way</p>
        </motion.div>
        
        <div className="screenshots-content">
          <div className="screenshot-tabs">
            {screenshots.map((screenshot, index) => (
              <button
                key={index}
                className={`screenshot-tab ${activeIndex === index ? 'active' : ''}`}
                onClick={() => setActiveIndex(index)}
              >
                <span className="tab-number">{String(index + 1).padStart(2, '0')}</span>
                <div className="tab-content">
                  <h4>{screenshot.title}</h4>
                  <p>{screenshot.description}</p>
                </div>
              </button>
            ))}
          </div>
          
          <motion.div
            key={activeIndex}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.3 }}
            className="screenshot-display"
          >
            <div className="screenshot-frame">
              <div className="frame-dots">
                <span></span>
                <span></span>
                <span></span>
              </div>
              <div className="screenshot-image">
                <img 
                  src={screenshots[activeIndex].image} 
                  alt={screenshots[activeIndex].title}
                  className="actual-screenshot"
                  onError={(e) => {
                    e.target.style.display = 'none';
                    e.target.nextSibling.style.display = 'block';
                  }}
                />
                <div className="screenshot-placeholder" style={{ display: 'none' }}>
                  <h4>{screenshots[activeIndex].title}</h4>
                  <p>{screenshots[activeIndex].description}</p>
                  <p style={{ marginTop: '1rem', fontSize: '0.9rem', opacity: 0.7 }}>
                    Screenshot preview coming soon
                  </p>
                </div>
              </div>
              
              <div className="screenshot-features">
                <h5>Key Features:</h5>
                <ul>
                  {screenshots[activeIndex].features.map((feature, index) => (
                    <li key={index}>{feature}</li>
                  ))}
                </ul>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
      
    </section>
  )
}

export default Screenshots