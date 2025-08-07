import { useState, useEffect, useRef } from 'react'

/**
 * Custom hook to detect when an element is in the viewport
 * Alternative to Framer Motion's whileInView for non-animated elements
 * @param {number} threshold - Intersection threshold (0-1)
 * @param {string} rootMargin - Root margin for intersection observer
 * @returns {array} [ref, isInView] - ref to attach to element, boolean if in view
 */
export const useInView = (threshold = 0.1, rootMargin = '0px') => {
  const [isInView, setIsInView] = useState(false)
  const [hasBeenInView, setHasBeenInView] = useState(false)
  const ref = useRef()
  
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsInView(true)
          if (!hasBeenInView) {
            setHasBeenInView(true)
          }
        } else {
          setIsInView(false)
        }
      },
      {
        threshold,
        rootMargin
      }
    )
    
    if (ref.current) {
      observer.observe(ref.current)
    }
    
    return () => {
      if (ref.current) {
        observer.unobserve(ref.current)
      }
    }
  }, [threshold, rootMargin])
  
  return [ref, isInView, hasBeenInView]
}