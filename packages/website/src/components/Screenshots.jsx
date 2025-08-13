import { motion } from 'framer-motion'
import { useState } from 'react'

const screenshots = [
  {
    title: "Main Interface",
    description: "Clean menu bar display showing your current AWS costs with trend indicators",
    image: "/AWSCostMonitor/screenshots/main-interface.png",
    width: 2000,
    height: 1125,
    features: ["Real-time cost display", "Profile switching", "Trend indicators"]
  },
  {
    title: "Calendar View",
    description: "Beautiful monthly calendar showing daily spending patterns with color-coded intensity",
    image: "/AWSCostMonitor/screenshots/calendar-view.png",
    width: 2000,
    height: 1125,
    features: ["Monthly spending calendar", "Color-coded daily costs", "Quick month navigation", "⌘K keyboard shortcut"]
  },
  {
    title: "Day Detail with Donut Chart",
    description: "Interactive donut chart showing service breakdown - click any calendar day or histogram bar to see details",
    image: "/AWSCostMonitor/screenshots/day-detail-donut.png",
    width: 2000,
    height: 1125,
    features: ["Interactive donut charts", "Click histogram bars for daily view", "Service cost breakdown", "Smart service grouping"]
  },
  {
    title: "Settings - Refresh Rate",
    description: "Configure intelligent refresh rates based on your budget and spending patterns",
    image: "/AWSCostMonitor/screenshots/settings-refresh-rate.png",
    width: 2000,
    height: 1125,
    features: ["Smart refresh rates", "API usage tracking", "Budget-based polling"]
  },
  {
    title: "Settings - Display Format",
    description: "Customize how costs appear in your menu bar with various formatting options",
    image: "/AWSCostMonitor/screenshots/settings-display-format.png",
    width: 2000,
    height: 1125,
    features: ["Currency formatting", "Display modes", "Visual customization"]
  },
  {
    title: "Help & Getting Started",
    description: "Built-in help system with setup guides and troubleshooting information",
    image: "/AWSCostMonitor/screenshots/help-getting-started.png",
    width: 2000,
    height: 1125,
    features: ["Setup guide", "Keyboard shortcuts", "Troubleshooting tips"]
  },
  {
    title: "Settings - Anomaly Detection",
    description: "Set up intelligent alerts for unusual spending patterns and budget overages",
    image: "/AWSCostMonitor/screenshots/settings-anomaly-detection.png",
    width: 2000,
    height: 1125,
    features: ["Smart alerts", "Budget monitoring", "Spending anomalies"]
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
                  alt={`AWSCostMonitor ${screenshots[activeIndex].title} - ${screenshots[activeIndex].description}`}
                  width={screenshots[activeIndex].width}
                  height={screenshots[activeIndex].height}
                  className="actual-screenshot"
                  loading="lazy"
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