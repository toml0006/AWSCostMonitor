import { Github, Linkedin, Heart, Mail, Coffee, Globe } from 'lucide-react'

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-brand">
            <h3>AWSCostMonitor</h3>
            <p>by MiddleOut</p>
            <p>Keep your AWS costs under control.</p>
            <p className="footer-tagline">
              Made with <Heart size={16} /> for developers who care about their AWS bills.
            </p>
          </div>
          
          <div className="footer-links">
            <h4>Product</h4>
            <a href="#features">Features</a>
            <a href="#how-it-works">How It Works</a>
            <a href="#pricing">Pricing</a>
            <a href="https://github.com/toml0006/AWSCostMonitor/releases">Download</a>
          </div>
          
          <div className="footer-links">
            <h4>Resources</h4>
            <a href="https://github.com/toml0006/AWSCostMonitor">GitHub</a>
            <a href="https://github.com/toml0006/AWSCostMonitor/wiki">Documentation</a>
            <a href="https://github.com/toml0006/AWSCostMonitor/issues">Support</a>
            <a href="#/privacy">Privacy Policy</a>
            <a href="https://github.com/toml0006/AWSCostMonitor/blob/main/LICENSE">License</a>
          </div>
          
          <div className="footer-links">
            <h4>Connect</h4>
            <a href="https://toml0006.github.io">
              <Globe size={20} />
              Portfolio
            </a>
            <a href="https://github.com/toml0006">
              <Github size={20} />
              GitHub
            </a>
            <a href="https://www.linkedin.com/in/jackson-tomlinson/">
              <Linkedin size={20} />
              LinkedIn
            </a>
            <a href="#" onClick={(e) => {
              e.preventDefault();
              const email = ['awsapp', '@', 'middleout', '.', 'dev'].join('');
              window.location.href = 'mailto:' + email;
            }}>
              <Mail size={20} />
              Email
            </a>
            <a href="https://buymeacoffee.com/jacksontomlinson">
              <Coffee size={20} />
              Buy Me a Coffee
            </a>
          </div>
        </div>
        
        <div className="footer-bottom">
          <p>© 2025 MiddleOut. AWSCostMonitor is open source under MIT License.</p>
          <p>Not affiliated with Amazon Web Services.</p>
          <p className="easter-egg-hint" style={{ fontSize: '0.75rem', opacity: 0.6, marginTop: '0.5rem' }}>
            💡 Psst... try pressing "$" for a surprise, or "L"/"D" to toggle dark mode!
          </p>
        </div>
      </div>
      
    </footer>
  )
}

export default Footer