import { motion } from 'framer-motion'
import { useState } from 'react'

const screenshots = [
  {
    title: "Menu Bar Dashboard",
    description: "Click the menu bar pill to reveal MTD spend, forecast, daily burn, a 7-day sparkline, and the top services — all without opening a browser tab.",
    image: "/screenshots/main-interface.webp",
    width: 1586,
    height: 992,
    features: ["MTD + forecast at a glance", "7-day burn sparkline", "Top services with %", "One-click AWS console"]
  },
  {
    title: "Cost Calendar",
    description: "A month at a glance — every day shaded by spend intensity so anomalies and weekend dips jump out instantly.",
    image: "/screenshots/calendar-view.webp",
    width: 1586,
    height: 992,
    features: ["Heatmap by spend intensity", "Month navigation", "⌘K to open from menu bar", "Running month total"]
  },
  {
    title: "Day Detail with Donut",
    description: "Click any day for a full service breakdown — a donut chart plus ranked service list with exact dollar amounts.",
    image: "/screenshots/day-detail-donut.webp",
    width: 1586,
    height: 992,
    features: ["Donut chart per service", "Ranked service list", "Exact dollars + percentages", "Day-level API refresh"]
  },
  {
    title: "Appearance",
    description: "Tune Ledger's four independent axes — Accent, Density, Contrast, and Color Scheme — plus menu-bar visuals and currency formatting.",
    image: "/screenshots/settings-appearance.webp",
    width: 1586,
    height: 992,
    features: ["5 accents: Amber / Mint / Plasma / Bone / System", "Comfortable / Compact density", "WCAG AAA contrast mode", "Menu-bar sparkline toggle"]
  },
  {
    title: "Per-Profile Refresh",
    description: "Pick a refresh interval per AWS profile — from tight 15-minute loops on hot accounts to 24-hour cadence on sleepy ones. API call budget is displayed inline.",
    image: "/screenshots/settings-refresh-rate.webp",
    width: 1586,
    height: 992,
    features: ["Independent interval per profile", "Quick-set presets: 1h / 2h / 8h / 24h", "Estimated monthly API cost", "Always-on auto-refresh"]
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