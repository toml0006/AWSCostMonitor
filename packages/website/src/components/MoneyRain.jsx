import { useState, useEffect, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import confetti from 'canvas-confetti'

const MoneyRain = () => {
  const [isActive, setIsActive] = useState(false)
  const [showParty, setShowParty] = useState(false)
  const [longPressTimer, setLongPressTimer] = useState(null)

  const triggerParty = useCallback(() => {
    if (isActive) return // Prevent multiple triggers
    
    setIsActive(true)
    setShowParty(true)

    // Track the easter egg event in Google Analytics
    if (window.gtag) {
      window.gtag('event', 'easter_egg_triggered', {
        event_category: 'Engagement',
        event_label: 'Money Rain Party',
        event_action: window.innerWidth < 768 ? 'mobile_long_press' : 'keyboard_press'
      })
    }

    // Create money emoji elements
    const moneyEmojis = ['💵', '💰', '💸', '💳', '🤑', '💎', '🏆', '🎉', '🍾', '🥂']
    const container = document.createElement('div')
    container.style.position = 'fixed'
    container.style.top = '0'
    container.style.left = '0'
    container.style.width = '100%'
    container.style.height = '100%'
    container.style.pointerEvents = 'none'
    container.style.zIndex = '9999'
    container.style.overflow = 'hidden' // Prevent horizontal scroll
    document.body.appendChild(container)

    // Create falling money
    for (let i = 0; i < 50; i++) {
      setTimeout(() => {
        const money = document.createElement('div')
        money.innerHTML = moneyEmojis[Math.floor(Math.random() * moneyEmojis.length)]
        money.style.position = 'absolute'
        money.style.left = Math.random() * 100 + '%'
        money.style.top = '-50px'
        money.style.fontSize = (Math.random() * 30 + 20) + 'px'
        money.style.animation = `moneyFall ${Math.random() * 3 + 2}s linear`
        money.style.transform = `rotate(${Math.random() * 360}deg)`
        container.appendChild(money)

        setTimeout(() => {
          money.remove()
        }, 5000)
      }, i * 100)
    }

    // Trigger confetti cannons
    const duration = 5 * 1000
    const animationEnd = Date.now() + duration
    const colors = ['#FFD700', '#00C851', '#33B5E5', '#FF4444', '#FFBB33']

    const frame = () => {
      confetti({
        particleCount: 3,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        colors: colors
      })
      confetti({
        particleCount: 3,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        colors: colors
      })

      if (Date.now() < animationEnd) {
        requestAnimationFrame(frame)
      }
    }
    frame()

    // Gold confetti burst
    setTimeout(() => {
      confetti({
        particleCount: 100,
        spread: 70,
        origin: { y: 0.6 },
        colors: ['#FFD700', '#FFA500', '#FFD700']
      })
    }, 500)

    // Clean up
    setTimeout(() => {
      container.remove()
      setIsActive(false)
      setShowParty(false)
    }, 6000)
  }, [])

  // Handle keyboard press for desktop
  useEffect(() => {
    const handleKeyPress = (e) => {
      if (e.key === '$' && !isActive) {
        triggerParty()
      }
    }

    window.addEventListener('keypress', handleKeyPress)
    return () => window.removeEventListener('keypress', handleKeyPress)
  }, [isActive, triggerParty])

  // Handle long press for mobile
  useEffect(() => {
    const handleTouchStart = (e) => {
      // Start timer for long press (800ms)
      const timer = setTimeout(() => {
        triggerParty()
      }, 800)
      setLongPressTimer(timer)
    }

    const handleTouchEnd = () => {
      // Clear timer if touch ends before long press duration
      if (longPressTimer) {
        clearTimeout(longPressTimer)
        setLongPressTimer(null)
      }
    }

    const handleTouchMove = () => {
      // Cancel long press if user moves finger (scrolling)
      if (longPressTimer) {
        clearTimeout(longPressTimer)
        setLongPressTimer(null)
      }
    }

    // Add touch listeners to the whole document for mobile
    if ('ontouchstart' in window) {
      document.addEventListener('touchstart', handleTouchStart, { passive: true })
      document.addEventListener('touchend', handleTouchEnd, { passive: true })
      document.addEventListener('touchmove', handleTouchMove, { passive: true })
      document.addEventListener('touchcancel', handleTouchEnd, { passive: true })
    }

    return () => {
      if ('ontouchstart' in window) {
        document.removeEventListener('touchstart', handleTouchStart)
        document.removeEventListener('touchend', handleTouchEnd)
        document.removeEventListener('touchmove', handleTouchMove)
        document.removeEventListener('touchcancel', handleTouchEnd)
      }
      if (longPressTimer) {
        clearTimeout(longPressTimer)
      }
    }
  }, [isActive, triggerParty, longPressTimer])

  // Add CSS animation
  useEffect(() => {
    const style = document.createElement('style')
    style.textContent = `
      @keyframes moneyFall {
        to {
          transform: translateY(calc(100vh + 100px)) rotate(720deg);
        }
      }
      
      @keyframes luxuryGlow {
        0%, 100% { 
          text-shadow: 0 0 20px gold, 0 0 40px gold, 0 0 60px gold;
          transform: scale(1);
        }
        50% { 
          text-shadow: 0 0 30px gold, 0 0 60px gold, 0 0 90px gold;
          transform: scale(1.1);
        }
      }
      
      @keyframes sparkle {
        0%, 100% { opacity: 0; }
        50% { opacity: 1; }
      }
    `
    document.head.appendChild(style)
    return () => style.remove()
  }, [])

  return (
    <AnimatePresence>
      {showParty && (
        <motion.div
          initial={{ opacity: 0, scale: 0.5 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.5 }}
          style={{
            position: 'fixed',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            zIndex: 10000,
            pointerEvents: 'none',
            textAlign: 'center'
          }}
        >
          <div
            style={{
              fontSize: '4rem',
              fontWeight: 'bold',
              background: 'linear-gradient(45deg, #FFD700, #FFA500, #FFD700)',
              backgroundClip: 'text',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              animation: 'luxuryGlow 2s ease-in-out',
              textShadow: '0 0 60px rgba(255, 215, 0, 0.8)',
              WebkitTextStroke: '2px #000',
              textStroke: '2px #000'
            }}
          >
            💰 MONEY PARTY! 💰
          </div>
          <div
            style={{
              fontSize: '2rem',
              marginTop: '1rem',
              color: '#FFD700',
              animation: 'luxuryGlow 2s ease-in-out 0.5s',
              WebkitTextStroke: '1px #000',
              textStroke: '1px #000'
            }}
          >
            Making it rain AWS savings! 🎉
          </div>
          
          {/* Sparkles */}
          {[...Array(10)].map((_, i) => (
            <div
              key={i}
              style={{
                position: 'absolute',
                fontSize: '2rem',
                left: `${Math.random() * 200 - 100}%`,
                top: `${Math.random() * 200 - 100}%`,
                animation: `sparkle ${Math.random() * 2 + 1}s ease-in-out ${Math.random()}s infinite`
              }}
            >
              ✨
            </div>
          ))}
        </motion.div>
      )}
    </AnimatePresence>
  )
}

export default MoneyRain