import { useState, useEffect } from 'react'
import { HashRouter as Router, Routes, Route } from 'react-router-dom'
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
import './styles/unsigned-guide.css'
import './styles/themes.css'

// Context
import { ThemeProvider } from './contexts/ThemeContext'

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
import UnsignedAppGuide from './components/UnsignedAppGuide'
import MoneyRain from './components/MoneyRain'
import ThemeToggle from './components/ThemeToggle'

function HomePage() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  return (
    <div className="app">
      <MoneyRain />
      <ThemeToggle />
      <MemphisPatterns />
      <div className="app-background" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'var(--color-bg)', zIndex: -2 }} />
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

function App() {
  return (
    <ThemeProvider>
      <Router>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/unsigned-app-guide" element={<UnsignedAppGuide />} />
        </Routes>
      </Router>
    </ThemeProvider>
  )
}

export default App