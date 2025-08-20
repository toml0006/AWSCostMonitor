import { motion } from 'framer-motion'
import { DollarSign, Menu, X } from 'lucide-react'
import { useLocation, Link, useNavigate } from 'react-router-dom'

const Navigation = ({ isMenuOpen, setIsMenuOpen }) => {
  const location = useLocation()
  const navigate = useNavigate()
  const isHomePage = location.pathname === '/'
  
  const handleNavClick = (sectionId) => {
    setIsMenuOpen(false)
    if (!isHomePage) {
      // Navigate to home page first
      navigate('/')
      // After navigation, scroll to the section
      setTimeout(() => {
        const element = document.getElementById(sectionId)
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'start' })
        }
      }, 200)
    }
  }
  
  return (
    <nav className="navigation">
      <div className="container">
        <div className="nav-content">
          <div className="nav-logo">
            <Link to="/" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', textDecoration: 'none', color: 'inherit' }}>
              <DollarSign size={32} />
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start' }}>
                <span>AWSCostMonitor</span>
                <span style={{ fontSize: '0.7rem', opacity: 0.8, marginTop: '-4px' }}>by MiddleOut</span>
              </div>
            </Link>
          </div>
          
          <div className={`nav-menu ${isMenuOpen ? 'active' : ''}`}>
            {isHomePage ? (
              <>
                <a href="#features" onClick={() => setIsMenuOpen(false)}>Features</a>
                <a href="#installation" onClick={() => setIsMenuOpen(false)}>Get Started</a>
                <a href="#pricing" onClick={() => setIsMenuOpen(false)}>Pricing</a>
              </>
            ) : (
              <>
                <Link to="/" onClick={() => setIsMenuOpen(false)}>Home</Link>
                <a href="#" onClick={(e) => { e.preventDefault(); handleNavClick('features'); }}>Features</a>
                <a href="#" onClick={(e) => { e.preventDefault(); handleNavClick('installation'); }}>Get Started</a>
                <a href="#" onClick={(e) => { e.preventDefault(); handleNavClick('pricing'); }}>Pricing</a>
              </>
            )}
            <Link to="/support" onClick={() => setIsMenuOpen(false)}>Support</Link>
            <Link to="/changelog" onClick={() => setIsMenuOpen(false)}>Changelog</Link>
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