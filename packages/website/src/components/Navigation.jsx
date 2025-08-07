import { motion } from 'framer-motion'
import { DollarSign, Menu, X } from 'lucide-react'

const Navigation = ({ isMenuOpen, setIsMenuOpen }) => {
  return (
    <nav className="navigation">
      <div className="container">
        <div className="nav-content">
          <div className="nav-logo">
            <DollarSign size={32} />
            <span>AWSCostMonitor</span>
          </div>
          
          <div className={`nav-menu ${isMenuOpen ? 'active' : ''}`}>
            <a href="#features" onClick={() => setIsMenuOpen(false)}>Features</a>
            <a href="#how-it-works" onClick={() => setIsMenuOpen(false)}>How It Works</a>
            <a href="#pricing" onClick={() => setIsMenuOpen(false)}>Pricing</a>
            <a href="https://github.com/yourusername/awscostmonitor" className="nav-github">
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
      
      <style>{`
        .navigation {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          background: rgba(255, 239, 213, 0.95);
          backdrop-filter: blur(10px);
          z-index: 1000;
          padding: var(--space-md) 0;
          box-shadow: var(--shadow-md);
        }
        
        .nav-content {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        
        .nav-logo {
          display: flex;
          align-items: center;
          gap: var(--space-sm);
          font-family: var(--font-primary);
          font-size: 1.25rem;
          font-weight: 700;
          color: var(--color-dark);
        }
        
        .nav-logo svg {
          color: var(--color-primary);
        }
        
        .nav-menu {
          display: flex;
          align-items: center;
          gap: var(--space-xl);
        }
        
        .nav-menu a {
          font-weight: 500;
          transition: color 0.3s ease;
        }
        
        .nav-menu a:hover {
          color: var(--color-primary);
        }
        
        .nav-github {
          padding: 0.5rem 1rem;
          background: var(--color-dark);
          color: var(--color-white) !important;
          border-radius: var(--radius-md);
          transition: transform 0.3s ease;
        }
        
        .nav-github:hover {
          transform: translateY(-2px);
        }
        
        .nav-toggle {
          display: none;
          background: none;
          color: var(--color-dark);
        }
        
        @media (max-width: 768px) {
          .nav-toggle {
            display: block;
          }
          
          .nav-menu {
            position: fixed;
            top: 70px;
            left: 0;
            right: 0;
            background: var(--color-white);
            flex-direction: column;
            padding: var(--space-lg);
            box-shadow: var(--shadow-xl);
            transform: translateX(-100%);
            transition: transform 0.3s ease;
          }
          
          .nav-menu.active {
            transform: translateX(0);
          }
        }
      `}</style>
    </nav>
  )
}

export default Navigation