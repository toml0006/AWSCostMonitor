import { motion } from 'framer-motion'
import { DollarSign, Menu, X } from 'lucide-react'

const Navigation = ({ isMenuOpen, setIsMenuOpen }) => {
  return (
    <nav className="navigation">
      <div className="container">
        <div className="nav-content">
          <div className="nav-logo">
            <DollarSign size={32} />
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start' }}>
              <span>AWSCostMonitor</span>
              <span style={{ fontSize: '0.7rem', opacity: 0.8, marginTop: '-4px' }}>by MiddleOut</span>
            </div>
          </div>
          
          <div className={`nav-menu ${isMenuOpen ? 'active' : ''}`}>
            <a href="#features" onClick={() => setIsMenuOpen(false)}>Features</a>
            <a href="#how-it-works" onClick={() => setIsMenuOpen(false)}>How It Works</a>
            <a href="#pricing" onClick={() => setIsMenuOpen(false)}>Pricing</a>
            <a href="https://github.com/toml0006/AWSCostMonitor" className="nav-github">
              GitHub
            </a>
          </div>
          
          <button 
            className="nav-toggle"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
          >
            {isMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>
      
    </nav>
  )
}

export default Navigation