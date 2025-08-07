const MemphisPatterns = () => {
  return (
    <svg style={{ position: 'absolute', width: 0, height: 0 }}>
      <defs>
        {/* Squiggle Pattern */}
        <pattern id="squiggle-pattern" x="0" y="0" width="100" height="40" patternUnits="userSpaceOnUse">
          <path
            d="M0,20 Q25,5 50,20 T100,20"
            stroke="var(--color-primary)"
            strokeWidth="3"
            fill="none"
            opacity="0.3"
          />
        </pattern>
        
        {/* Dots Pattern */}
        <pattern id="dots-pattern" x="0" y="0" width="30" height="30" patternUnits="userSpaceOnUse">
          <circle cx="15" cy="15" r="3" fill="var(--color-secondary)" opacity="0.5" />
        </pattern>
        
        {/* Zigzag Pattern */}
        <pattern id="zigzag-pattern" x="0" y="0" width="40" height="40" patternUnits="userSpaceOnUse">
          <path
            d="M0,20 L10,10 L20,20 L30,10 L40,20"
            stroke="var(--color-tertiary)"
            strokeWidth="2"
            fill="none"
            opacity="0.4"
          />
        </pattern>
        
        {/* Confetti Pattern */}
        <pattern id="confetti-pattern" x="0" y="0" width="60" height="60" patternUnits="userSpaceOnUse">
          <rect x="10" y="10" width="8" height="8" fill="var(--color-primary)" transform="rotate(45 14 14)" />
          <circle cx="40" cy="20" r="4" fill="var(--color-secondary)" />
          <polygon points="20,40 25,50 15,50" fill="var(--color-tertiary)" />
          <rect x="45" y="45" width="6" height="6" fill="var(--color-accent)" />
        </pattern>
        
        {/* Cross Pattern */}
        <pattern id="cross-pattern" x="0" y="0" width="50" height="50" patternUnits="userSpaceOnUse">
          <path d="M25,15 L25,35 M15,25 L35,25" stroke="var(--color-accent)" strokeWidth="3" opacity="0.3" />
        </pattern>
      </defs>
    </svg>
  )
}

export default MemphisPatterns