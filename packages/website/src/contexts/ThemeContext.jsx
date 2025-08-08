import { createContext, useContext, useState, useEffect } from 'react'

const ThemeContext = createContext()

export const useTheme = () => {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider')
  }
  return context
}

export const ThemeProvider = ({ children }) => {
  const [theme, setTheme] = useState(() => {
    // Get saved theme from localStorage or default to 'system'
    const savedTheme = localStorage.getItem('theme')
    return savedTheme || 'system'
  })

  // Determine the actual theme to apply
  const getActualTheme = () => {
    if (theme === 'system') {
      // Check system preference
      return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'ultra-dark' : 'light'
    }
    return theme
  }

  const [actualTheme, setActualTheme] = useState(getActualTheme())

  // Update theme in localStorage and apply to document
  useEffect(() => {
    localStorage.setItem('theme', theme)
    const actual = getActualTheme()
    setActualTheme(actual)
    
    // Remove all theme classes first
    document.documentElement.classList.remove('light', 'ultra-dark')
    
    // Add the appropriate theme class
    if (actual === 'ultra-dark') {
      document.documentElement.classList.add('ultra-dark')
    } else {
      document.documentElement.classList.add('light')
    }
  }, [theme])

  // Listen for system theme changes
  useEffect(() => {
    if (theme === 'system') {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
      
      const handleChange = (e) => {
        const actual = e.matches ? 'ultra-dark' : 'light'
        setActualTheme(actual)
        document.documentElement.classList.remove('light', 'ultra-dark')
        document.documentElement.classList.add(actual)
      }
      
      mediaQuery.addEventListener('change', handleChange)
      return () => mediaQuery.removeEventListener('change', handleChange)
    }
  }, [theme])

  const cycleTheme = () => {
    // Cycle through: light -> ultra-dark -> system -> light
    setTheme(current => {
      if (current === 'light') return 'ultra-dark'
      if (current === 'ultra-dark') return 'system'
      return 'light'
    })
  }

  return (
    <ThemeContext.Provider value={{ theme, setTheme, actualTheme, cycleTheme }}>
      {children}
    </ThemeContext.Provider>
  )
}