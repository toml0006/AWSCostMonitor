import { Sun, Moon, Monitor } from 'lucide-react'
import { useTheme } from '../contexts/ThemeContext'
import { motion, AnimatePresence } from 'framer-motion'

const ThemeToggle = () => {
  const { theme, cycleTheme, actualTheme } = useTheme()

  const getIcon = () => {
    if (theme === 'light') return <Sun size={20} />
    if (theme === 'ultra-dark') return <Moon size={20} />
    return <Monitor size={20} />
  }

  const getLabel = () => {
    if (theme === 'light') return 'Light'
    if (theme === 'ultra-dark') return 'Ultra Dark'
    return 'System'
  }

  const getTooltip = () => {
    if (theme === 'light') return 'Switch to Ultra Dark mode'
    if (theme === 'ultra-dark') return 'Switch to System theme'
    return 'Switch to Light mode'
  }

  return (
    <motion.button
      className="theme-toggle"
      onClick={cycleTheme}
      title={getTooltip()}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      style={{
        position: 'fixed',
        bottom: '2rem',
        right: '2rem',
        zIndex: 1000,
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        padding: '0.75rem 1rem',
        borderRadius: '2rem',
        border: '2px solid var(--theme-toggle-border)',
        background: 'var(--theme-toggle-bg)',
        color: 'var(--theme-toggle-color)',
        cursor: 'pointer',
        fontFamily: 'var(--font-secondary)',
        fontSize: '0.875rem',
        fontWeight: '500',
        boxShadow: 'var(--shadow-lg)',
        backdropFilter: 'blur(10px)',
        transition: 'all 0.3s ease'
      }}
    >
      <AnimatePresence mode="wait">
        <motion.div
          key={theme}
          initial={{ rotate: -180, opacity: 0 }}
          animate={{ rotate: 0, opacity: 1 }}
          exit={{ rotate: 180, opacity: 0 }}
          transition={{ duration: 0.3 }}
          style={{ display: 'flex', alignItems: 'center' }}
        >
          {getIcon()}
        </motion.div>
      </AnimatePresence>
      <span>{getLabel()}</span>
    </motion.button>
  )
}

export default ThemeToggle