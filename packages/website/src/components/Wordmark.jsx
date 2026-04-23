const MIDDLEOUT_ACCENT = '#0d9669'

const Wordmark = ({ href = 'https://middleout.dev', className = '', style = {} }) => {
  const accent = { color: MIDDLEOUT_ACCENT }
  const inner = (
    <span
      className={`wordmark ${className}`}
      style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Consolas, monospace', fontWeight: 700, letterSpacing: '-0.02em', whiteSpace: 'nowrap', ...style }}
    >
      <span style={accent}>{'{'}</span>
      <span>middle</span>
      <span style={accent}>/</span>
      <span>out</span>
      <span style={accent}>{'}'}</span>
    </span>
  )
  if (!href) return inner
  return (
    <a href={href} target="_blank" rel="noopener noreferrer" style={{ color: 'inherit', textDecoration: 'none' }}>
      {inner}
    </a>
  )
}

export default Wordmark
