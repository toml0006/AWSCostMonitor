import { Github, Twitter, Heart, Mail } from 'lucide-react'

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-brand">
            <h3>AWSCostMonitor</h3>
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
            <a href="https://github.com/yourusername/awscostmonitor/releases">Download</a>
          </div>
          
          <div className="footer-links">
            <h4>Resources</h4>
            <a href="https://github.com/yourusername/awscostmonitor">GitHub</a>
            <a href="https://github.com/yourusername/awscostmonitor/wiki">Documentation</a>
            <a href="https://github.com/yourusername/awscostmonitor/issues">Support</a>
            <a href="https://github.com/yourusername/awscostmonitor/blob/main/LICENSE">License</a>
          </div>
          
          <div className="footer-links">
            <h4>Connect</h4>
            <a href="https://github.com/yourusername">
              <Github size={20} />
              GitHub
            </a>
            <a href="https://twitter.com/yourusername">
              <Twitter size={20} />
              Twitter
            </a>
            <a href="mailto:hello@example.com">
              <Mail size={20} />
              Email
            </a>
          </div>
        </div>
        
        <div className="footer-bottom">
          <p>© 2024 AWSCostMonitor. Open source under MIT License.</p>
          <p>Not affiliated with Amazon Web Services.</p>
        </div>
      </div>
      
    </footer>
  )
}

export default Footer