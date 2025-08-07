import { motion } from 'framer-motion'

const GeometricShapes = () => {
  return (
    <>
      {/* Memphis-style floating shapes and patterns */}
      <div className="geometric-shapes">
        {/* Large rotating circle with dots */}
        <motion.div
          className="memphis-circle"
          style={{
            width: '120px',
            height: '120px',
            background: 'var(--color-primary)',
            top: '10%',
            left: '5%',
            opacity: 0.9,
            position: 'absolute',
          }}
          animate={{
            y: [0, -30, 0],
            rotate: [0, 360],
          }}
          transition={{
            duration: 20,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        
        {/* Dots grid pattern */}
        <div 
          className="memphis-dots-grid animate-pulse-scale"
          style={{
            position: 'absolute',
            top: '15%',
            right: '8%',
            opacity: 0.6,
          }}
        />
        
        {/* Squiggle element */}
        <div 
          className="memphis-squiggle animate-squiggle"
          style={{
            position: 'absolute',
            top: '25%',
            left: '15%',
            transform: 'scale(1.5)',
            opacity: 0.8,
          }}
        />
        
        {/* Rotating diamond */}
        <motion.div
          className="geometric-shape shape-square"
          style={{
            position: 'absolute',
            width: '60px',
            height: '60px',
            background: 'var(--color-secondary)',
            top: '30%',
            right: '10%',
            transform: 'rotate(45deg)',
            borderRadius: '10px',
            opacity: 0.8,
          }}
          animate={{
            rotate: [45, 405],
            scale: [1, 1.2, 1],
          }}
          transition={{
            duration: 15,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        
        {/* Memphis cross */}
        <div 
          className="memphis-cross animate-float-rotate"
          style={{
            position: 'absolute',
            top: '40%',
            left: '90%',
            opacity: 0.7,
          }}
        />
        
        {/* Triangle patterns */}
        <motion.div
          className="memphis-triangle-up"
          style={{
            position: 'absolute',
            top: '60%',
            left: '8%',
            opacity: 0.8,
          }}
          animate={{
            x: [0, 30, 0],
            y: [0, -20, 0],
          }}
          transition={{
            duration: 18,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        
        <div
          className="memphis-triangle-down"
          style={{
            position: 'absolute',
            top: '70%',
            right: '15%',
            opacity: 0.8,
          }}
        />
        
        {/* Small circles scattered */}
        <motion.div
          className="memphis-circle"
          style={{
            position: 'absolute',
            width: '40px',
            height: '40px',
            background: 'var(--color-accent)',
            bottom: '20%',
            right: '5%',
            opacity: 0.8,
          }}
          animate={{
            scale: [1, 1.5, 1],
            opacity: [0.5, 1, 0.5],
          }}
          transition={{
            duration: 10,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        
        <motion.div
          className="memphis-circle"
          style={{
            position: 'absolute',
            width: '25px',
            height: '25px',
            background: 'var(--color-tertiary)',
            top: '45%',
            left: '3%',
            opacity: 0.9,
          }}
          animate={{
            y: [0, 20, 0],
          }}
          transition={{
            duration: 5,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        
        {/* More dots grids at different positions */}
        <div 
          className="memphis-dots-grid"
          style={{
            position: 'absolute',
            top: '75%',
            left: '20%',
            width: '150px',
            height: '150px',
            opacity: 0.5,
          }}
        />
        
        {/* Blob shape */}
        <motion.div
          className="blob-1"
          style={{
            position: 'absolute',
            width: '80px',
            height: '80px',
            top: '50%',
            right: '25%',
            opacity: 0.3,
          }}
          animate={{
            x: [0, 20, 0],
            y: [0, -30, 0],
          }}
          transition={{
            duration: 12,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        
        {/* Another squiggle */}
        <div 
          className="memphis-squiggle"
          style={{
            position: 'absolute',
            bottom: '10%',
            left: '50%',
            transform: 'rotate(90deg) scale(0.8)',
            opacity: 0.7,
          }}
        />
        
        {/* Zigzag pattern overlay */}
        <div 
          className="pattern-zigzag"
          style={{
            position: 'absolute',
            top: '35%',
            right: '30%',
            width: '200px',
            height: '200px',
            opacity: 0.05,
          }}
        />
        
        {/* More Memphis crosses */}
        <div 
          className="memphis-cross"
          style={{
            position: 'absolute',
            bottom: '30%',
            right: '40%',
            transform: 'scale(0.7)',
            opacity: 0.6,
          }}
        />
        
        {/* Confetti pattern area */}
        <div 
          className="pattern-confetti"
          style={{
            position: 'absolute',
            top: '80%',
            right: '60%',
            width: '100px',
            height: '100px',
            opacity: 0.3,
            borderRadius: '50%',
          }}
        />
        
        {/* Extra large dots for visibility */}
        <motion.div
          className="memphis-circle"
          style={{
            position: 'absolute',
            width: '80px',
            height: '80px',
            background: 'var(--color-primary)',
            top: '5%',
            right: '20%',
            opacity: 0.4,
          }}
          animate={{
            scale: [1, 1.1, 1],
            opacity: [0.4, 0.7, 0.4],
          }}
          transition={{
            duration: 6,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        
        <motion.div
          className="memphis-circle"
          style={{
            position: 'absolute',
            width: '60px',
            height: '60px',
            background: 'var(--color-secondary)',
            bottom: '15%',
            left: '10%',
            opacity: 0.5,
          }}
          animate={{
            x: [0, 20, 0],
            rotate: [0, 180, 360],
          }}
          transition={{
            duration: 12,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        
        {/* Large squiggle patterns */}
        <div 
          className="memphis-squiggle"
          style={{
            position: 'absolute',
            top: '55%',
            right: '5%',
            transform: 'scale(2) rotate(45deg)',
            opacity: 0.3,
          }}
        />
        
        <div 
          className="memphis-squiggle"
          style={{
            position: 'absolute',
            bottom: '40%',
            left: '25%',
            transform: 'scale(1.8) rotate(-30deg)',
            opacity: 0.4,
          }}
        />
      </div>
    </>
  )
}

export default GeometricShapes