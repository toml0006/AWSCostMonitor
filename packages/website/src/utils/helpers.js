/**
 * Helper utilities for the marketing website
 */

/**
 * Format currency value for display
 * @param {number} amount - Dollar amount
 * @param {boolean} abbreviated - Whether to abbreviate large numbers
 * @returns {string} Formatted currency string
 */
export const formatCurrency = (amount, abbreviated = false) => {
  if (abbreviated && amount >= 1000) {
    return `$${(amount / 1000).toFixed(1)}k`
  }
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(amount)
}

/**
 * Calculate estimated monthly API cost based on refresh frequency
 * @param {number} refreshMinutes - Minutes between refreshes
 * @returns {object} Cost breakdown
 */
export const calculateAPICost = (refreshMinutes = 60) => {
  const requestsPerDay = Math.floor((24 * 60) / refreshMinutes)
  const requestsPerMonth = requestsPerDay * 30
  const monthlyCost = requestsPerMonth * 0.01
  
  return {
    requestsPerDay,
    requestsPerMonth,
    monthlyCost: Math.round(monthlyCost * 100) / 100
  }
}

/**
 * Smooth scroll to element with offset for fixed nav
 * @param {string} elementId - Target element ID
 * @param {number} offset - Offset for fixed navigation
 */
export const scrollToElement = (elementId, offset = 80) => {
  const element = document.getElementById(elementId.replace('#', ''))
  if (element) {
    const elementPosition = element.getBoundingClientPosition().top
    const offsetPosition = elementPosition + window.pageYOffset - offset
    
    window.scrollTo({
      top: offsetPosition,
      behavior: 'smooth'
    })
  }
}

/**
 * Handle image loading with fallback
 * @param {Event} event - Image error event
 * @param {function} setFallback - Function to set fallback state
 */
export const handleImageError = (event, setFallback) => {
  event.target.style.display = 'none'
  if (setFallback) {
    setFallback(true)
  }
  
  // Show fallback content if it exists
  const fallback = event.target.nextElementSibling
  if (fallback && fallback.classList.contains('fallback')) {
    fallback.style.display = 'block'
  }
}

/**
 * Debounce function for performance optimization
 * @param {function} func - Function to debounce
 * @param {number} wait - Wait time in milliseconds
 * @returns {function} Debounced function
 */
export const debounce = (func, wait) => {
  let timeout
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout)
      func(...args)
    }
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}

/**
 * Check if element is in viewport
 * @param {HTMLElement} element - Element to check
 * @param {number} threshold - Threshold percentage (0-1)
 * @returns {boolean} Whether element is in viewport
 */
export const isInViewport = (element, threshold = 0.1) => {
  const rect = element.getBoundingClientRect()
  const windowHeight = window.innerHeight || document.documentElement.clientHeight
  const windowWidth = window.innerWidth || document.documentElement.clientWidth
  
  const elementHeight = rect.bottom - rect.top
  const elementWidth = rect.right - rect.left
  
  const verticalVisible = rect.top + (elementHeight * threshold) < windowHeight &&
                         rect.bottom - (elementHeight * threshold) > 0
  
  const horizontalVisible = rect.left + (elementWidth * threshold) < windowWidth &&
                           rect.right - (elementWidth * threshold) > 0
  
  return verticalVisible && horizontalVisible
}

/**
 * Generate Memphis design random position within safe bounds
 * @param {number} maxX - Maximum X position
 * @param {number} maxY - Maximum Y position  
 * @param {number} padding - Padding from edges
 * @returns {object} Position coordinates
 */
export const getRandomPosition = (maxX, maxY, padding = 50) => {
  return {
    x: padding + Math.random() * (maxX - padding * 2),
    y: padding + Math.random() * (maxY - padding * 2)
  }
}

/**
 * Get contrasting text color for background
 * @param {string} backgroundColor - Background color hex
 * @returns {string} Either 'white' or 'black'
 */
export const getContrastingColor = (backgroundColor) => {
  // Remove # if present
  const color = backgroundColor.replace('#', '')
  
  // Convert to RGB
  const r = parseInt(color.substr(0, 2), 16)
  const g = parseInt(color.substr(2, 2), 16)
  const b = parseInt(color.substr(4, 2), 16)
  
  // Calculate brightness
  const brightness = (r * 299 + g * 587 + b * 114) / 1000
  
  return brightness > 128 ? 'black' : 'white'
}