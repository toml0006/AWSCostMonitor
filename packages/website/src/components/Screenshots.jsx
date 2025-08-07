import { motion } from 'framer-motion'
import { useState } from 'react'

const screenshots = [
  {
    title: "Menu Bar Display",
    description: "Always visible cost tracking in your menu bar",
    image: "/screenshots/menu-bar.png"
  },
  {
    title: "Main Interface",
    description: "Detailed cost breakdown with 14-day histograms",
    image: "/screenshots/main-interface.png"
  },
  {
    title: "Settings & Configuration",
    description: "Customize refresh rates, budgets, and display options",
    image: "/screenshots/settings-window.png"
  },
  {
    title: "Help & Documentation",
    description: "Comprehensive help system with keyboard shortcuts",
    image: "/screenshots/help-dialog.png"
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
                />
              </div>
            </div>
          </motion.div>
        </div>
      </div>
      
    </section>
  )
}

export default Screenshots