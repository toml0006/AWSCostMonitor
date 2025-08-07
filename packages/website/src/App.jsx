import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  DollarSign, 
  TrendingDown, 
  Bell, 
  Shield, 
  Zap, 
  Eye,
  BarChart3,
  Cloud,
  Download,
  ChevronRight,
  Check,
  Menu,
  X,
  Github,
  Twitter,
  Monitor
} from 'lucide-react'
import './App.css'
import './styles/components.css'
import './styles/memphis.css'

// Components
import Hero from './components/Hero'
import Features from './components/Features'
import HowItWorks from './components/HowItWorks'
import Pricing from './components/Pricing'
import Screenshots from './components/Screenshots'
import Installation from './components/Installation'
import Footer from './components/Footer'
import Navigation from './components/Navigation'
import GeometricShapes from './components/GeometricShapes'
import MemphisPatterns from './components/MemphisPatterns'

function App() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  return (
    <div className="app">
      <MemphisPatterns />
      <div className="app-background" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'var(--color-light)', zIndex: -2 }} />
      <GeometricShapes />
      <div className="app-content" style={{ position: 'relative', zIndex: 1 }}>
        <Navigation isMenuOpen={isMenuOpen} setIsMenuOpen={setIsMenuOpen} />
        <Hero />
        <Features />
        <Screenshots />
        <Installation />
        <HowItWorks />
        <Pricing />
        <Footer />
      </div>
    </div>
  )
}

export default App