import { motion } from 'framer-motion'

const GeometricShapes = () => {
  return (
    <div className="geometric-shapes">
      <motion.div
        className="shape shape-circle"
        animate={{
          x: [0, 100, 0],
          y: [0, -50, 0],
        }}
        transition={{
          duration: 20,
          repeat: Infinity,
          ease: "linear"
        }}
      />
      
      <motion.div
        className="shape shape-triangle"
        animate={{
          rotate: 360,
        }}
        transition={{
          duration: 30,
          repeat: Infinity,
          ease: "linear"
        }}
      />
      
      <motion.div
        className="shape shape-square"
        animate={{
          x: [0, -100, 0],
          y: [0, 100, 0],
        }}
        transition={{
          duration: 25,
          repeat: Infinity,
          ease: "linear"
        }}
      />
      
      <motion.div
        className="shape shape-zigzag"
        animate={{
          scale: [1, 1.2, 1],
        }}
        transition={{
          duration: 15,
          repeat: Infinity,
          ease: "easeInOut"
        }}
      />
      
      <motion.div
        className="shape shape-dots"
        animate={{
          opacity: [0.3, 0.6, 0.3],
        }}
        transition={{
          duration: 10,
          repeat: Infinity,
          ease: "easeInOut"
        }}
      />
      
      <style jsx>{`
        .geometric-shapes {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          pointer-events: none;
          z-index: 0;
          overflow: hidden;
        }
        
        .shape {
          position: absolute;
          opacity: 0.1;
        }
        
        .shape-circle {
          width: 300px;
          height: 300px;
          background: var(--color-primary);
          border-radius: 50%;
          top: 10%;
          right: 10%;
        }
        
        .shape-triangle {
          width: 0;
          height: 0;
          border-left: 150px solid transparent;
          border-right: 150px solid transparent;
          border-bottom: 260px solid var(--color-secondary);
          top: 50%;
          left: 5%;
        }
        
        .shape-square {
          width: 200px;
          height: 200px;
          background: var(--color-tertiary);
          bottom: 20%;
          right: 15%;
          transform: rotate(45deg);
        }
        
        .shape-zigzag {
          width: 400px;
          height: 400px;
          background: repeating-linear-gradient(
            45deg,
            var(--color-accent),
            var(--color-accent) 10px,
            transparent 10px,
            transparent 20px
          );
          top: 60%;
          left: 50%;
          transform: translate(-50%, -50%);
        }
        
        .shape-dots {
          width: 100%;
          height: 100%;
          background-image: radial-gradient(circle, var(--color-primary) 2px, transparent 2px);
          background-size: 50px 50px;
        }
        
        @media (max-width: 768px) {
          .shape {
            opacity: 0.05;
          }
          
          .shape-circle {
            width: 150px;
            height: 150px;
          }
          
          .shape-square {
            width: 100px;
            height: 100px;
          }
        }
      `}</style>
    </div>
  )
}

export default GeometricShapes