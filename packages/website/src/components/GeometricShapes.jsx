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
            opacity: 0.8,
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
            top: '15%',
            right: '8%',
          }}
        />
        
        {/* Squiggle element */}
        <div 
          className="memphis-squiggle animate-squiggle"
          style={{
            top: '25%',
            left: '15%',
            transform: 'scale(1.5)',
          }}
        />
        
        {/* Rotating diamond */}
        <motion.div
          className="geometric-shape shape-square"
          style={{
            width: '60px',
            height: '60px',
            background: 'var(--color-secondary)',
            top: '30%',
            right: '10%',
            transform: 'rotate(45deg)',
            borderRadius: '10px',
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
            top: '40%',
            left: '90%',
          }}
        />
        
        {/* Triangle patterns */}
        <motion.div
          className="memphis-triangle-up"
          style={{
            top: '60%',
            left: '8%',
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
            top: '70%',
            right: '15%',
            opacity: 0.6,
          }}
        />
        
        {/* Small circles scattered */}
        <motion.div
          className="memphis-circle"
          style={{
            width: '40px',
            height: '40px',
            background: 'var(--color-accent)',
            bottom: '20%',
            right: '5%',
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
            width: '25px',
            height: '25px',
            background: 'var(--color-tertiary)',
            top: '45%',
            left: '3%',
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
            top: '75%',
            left: '20%',
            width: '150px',
            height: '150px',
            opacity: 0.2,
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
            bottom: '10%',
            left: '50%',
            transform: 'rotate(90deg) scale(0.8)',
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
            bottom: '30%',
            right: '40%',
            transform: 'scale(0.7)',
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
            opacity: 0.1,
            borderRadius: '50%',
          }}
        />
      </div>
    </>
  )
}

export default GeometricShapes