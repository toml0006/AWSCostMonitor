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

function App() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  return (
    <div className="app">
      <GeometricShapes />
      <Navigation isMenuOpen={isMenuOpen} setIsMenuOpen={setIsMenuOpen} />
      <Hero />
      <Features />
      <Screenshots />
      <Installation />
      <HowItWorks />
      <Pricing />
      <Footer />
    </div>
  )
}

export default App