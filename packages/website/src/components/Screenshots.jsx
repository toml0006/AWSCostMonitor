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
    <section id="screenshots" className="screenshots">
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
      
      <style jsx>{`
        .screenshots {
          background: var(--color-white);
        }
        
        .section-header {
          text-align: center;
          margin-bottom: var(--space-3xl);
        }
        
        .section-header h2 {
          margin-bottom: var(--space-md);
        }
        
        .screenshots-content {
          display: grid;
          grid-template-columns: 1fr 2fr;
          gap: var(--space-2xl);
          align-items: start;
        }
        
        .screenshot-tabs {
          display: flex;
          flex-direction: column;
          gap: var(--space-md);
        }
        
        .screenshot-tab {
          display: flex;
          align-items: center;
          gap: var(--space-md);
          padding: var(--space-md);
          background: var(--color-light);
          border-radius: var(--radius-lg);
          text-align: left;
          transition: all 0.3s ease;
          border: 3px solid transparent;
        }
        
        .screenshot-tab.active {
          background: var(--color-white);
          border-color: var(--color-primary);
          box-shadow: var(--shadow-md);
        }
        
        .screenshot-tab:hover {
          transform: translateX(5px);
        }
        
        .tab-number {
          font-size: 1.5rem;
          font-weight: 700;
          color: var(--color-primary);
          font-family: var(--font-primary);
        }
        
        .tab-content h4 {
          margin-bottom: 0.25rem;
          font-size: 1rem;
        }
        
        .tab-content p {
          font-size: 0.875rem;
          opacity: 0.7;
        }
        
        .screenshot-frame {
          background: var(--color-dark);
          border-radius: var(--radius-lg);
          padding: var(--space-sm);
          box-shadow: var(--shadow-2xl);
        }
        
        .frame-dots {
          display: flex;
          gap: 0.5rem;
          margin-bottom: var(--space-sm);
        }
        
        .frame-dots span {
          width: 12px;
          height: 12px;
          border-radius: 50%;
          background: var(--color-primary);
        }
        
        .frame-dots span:nth-child(2) {
          background: var(--color-tertiary);
        }
        
        .frame-dots span:nth-child(3) {
          background: var(--color-secondary);
        }
        
        .screenshot-image {
          background: white;
          border-radius: var(--radius-md);
          aspect-ratio: 16/10;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        .actual-screenshot {
          width: 100%;
          height: 100%;
          object-fit: contain;
          border-radius: var(--radius-md);
        }
        
        @media (max-width: 768px) {
          .screenshots-content {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </section>
  )
}

export default Screenshots