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
      
      <style jsx>{`
        .footer {
          background: var(--color-dark);
          color: var(--color-white);
          padding: var(--space-3xl) 0 var(--space-xl);
          margin-top: var(--space-3xl);
        }
        
        .footer-content {
          display: grid;
          grid-template-columns: 2fr 1fr 1fr 1fr;
          gap: var(--space-2xl);
          margin-bottom: var(--space-2xl);
        }
        
        .footer-brand h3 {
          margin-bottom: var(--space-sm);
          color: var(--color-white);
        }
        
        .footer-brand p {
          opacity: 0.8;
          margin-bottom: var(--space-sm);
        }
        
        .footer-tagline {
          display: flex;
          align-items: center;
          gap: 0.25rem;
        }
        
        .footer-tagline svg {
          color: var(--color-primary);
        }
        
        .footer-links {
          display: flex;
          flex-direction: column;
          gap: var(--space-sm);
        }
        
        .footer-links h4 {
          margin-bottom: var(--space-sm);
          color: var(--color-white);
        }
        
        .footer-links a {
          opacity: 0.8;
          transition: opacity 0.3s ease;
          display: flex;
          align-items: center;
          gap: var(--space-xs);
        }
        
        .footer-links a:hover {
          opacity: 1;
          color: var(--color-secondary);
        }
        
        .footer-bottom {
          padding-top: var(--space-xl);
          border-top: 1px solid rgba(255, 255, 255, 0.1);
          text-align: center;
          opacity: 0.6;
        }
        
        .footer-bottom p {
          font-size: 0.875rem;
        }
        
        @media (max-width: 768px) {
          .footer-content {
            grid-template-columns: 1fr;
            text-align: center;
          }
          
          .footer-links {
            align-items: center;
          }
        }
      `}</style>
    </footer>
  )
}

export default Footer