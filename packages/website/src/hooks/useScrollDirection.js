import { useState, useEffect } from 'react'

/**
 * Custom hook to track scroll direction
 * Useful for showing/hiding navigation on scroll
 * @param {number} threshold - Minimum scroll distance to trigger change
 * @returns {string} 'up', 'down', or 'static'
 */
export const useScrollDirection = (threshold = 0) => {
  const [scrollDirection, setScrollDirection] = useState('static')
  
  useEffect(() => {
    let lastScrollY = window.pageYOffset
    let ticking = false
    
    const updateScrollDirection = () => {
      const scrollY = window.pageYOffset
      const direction = scrollY > lastScrollY ? 'down' : 'up'
      
      if (direction !== scrollDirection && 
          (scrollY - lastScrollY > threshold || scrollY - lastScrollY < -threshold)) {
        setScrollDirection(direction)
      }
      
      lastScrollY = scrollY > 0 ? scrollY : 0
      ticking = false
    }
    
    const onScroll = () => {
      if (!ticking) {
        requestAnimationFrame(updateScrollDirection)
        ticking = true
      }
    }
    
    window.addEventListener('scroll', onScroll)
    
    return () => window.removeEventListener('scroll', onScroll)
  }, [scrollDirection, threshold])
  
  return scrollDirection
}