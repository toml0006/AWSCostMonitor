import { useState } from 'react'
import { HelpCircle, MessageCircle, Mail, AlertCircle, DollarSign, Download, Settings, Shield, ChevronDown, ChevronUp, ExternalLink, CreditCard, AlertTriangle } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import Navigation from './Navigation'
import Footer from './Footer'
import GeometricShapes from './GeometricShapes'
import MemphisPatterns from './MemphisPatterns'

function Support() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [openFaq, setOpenFaq] = useState(null)

  const toggleFaq = (index) => {
    setOpenFaq(openFaq === index ? null : index)
  }

  const faqCategories = [
    {
      title: "Purchase & Licensing",
      icon: <CreditCard size={24} />,
      color: "primary",
      faqs: [
        {
          question: "Why does the app show 'Unable to load pricing' in the purchase window?",
          answer: "This can happen if the App Store is having connectivity issues or if there's a problem loading the in-app purchase information. Please try:\n\n1. Ensure you have a stable internet connection\n2. Restart the app\n3. Check if you're signed into the Mac App Store\n4. If the issue persists, you can purchase directly from our website at awscostmonitor.io\n\nWe're actively working with Apple to resolve any App Store connectivity issues.",
          highlight: true
        },
        {
          question: "How do I purchase AWSCostMonitor?",
          answer: "You can purchase AWSCostMonitor through two methods:\n\n1. **Mac App Store**: Download from the App Store and purchase the Pro version through in-app purchase ($29.99)\n2. **Direct Purchase**: Buy directly from awscostmonitor.io and download the standalone version\n\nBoth versions include the same features and lifetime updates."
        },
        {
          question: "Is this a subscription or one-time purchase?",
          answer: "AWSCostMonitor is a one-time purchase of $29.99. No subscriptions, no recurring fees. You get lifetime updates and all future features included."
        },
        {
          question: "Can I use my license on multiple Macs?",
          answer: "Yes! Your license is valid for all your personal Macs. If you purchased through the Mac App Store, you can install it on any Mac signed into your Apple ID. Direct purchases include a license key that can be used on up to 3 machines."
        },
        {
          question: "What's included in the free trial?",
          answer: "The 14-day free trial includes ALL Pro features:\n• Unlimited AWS profiles\n• Smart refresh with budgets\n• Cost forecasting & trends\n• Historical data & comparisons\n• Service breakdown views\n• Export functionality\n• Keyboard shortcuts\n• All future updates"
        },
        {
          question: "Do you offer refunds?",
          answer: "Yes! We offer a 30-day money-back guarantee. If you're not satisfied, contact support@awscostmonitor.io for a full refund. For App Store purchases, you can also request a refund through Apple."
        }
      ]
    },
    {
      title: "Installation & Setup",
      icon: <Download size={24} />,
      color: "secondary",
      faqs: [
        {
          question: "What are the system requirements?",
          answer: "AWSCostMonitor requires:\n• macOS 13.0 (Ventura) or later\n• Apple Silicon (M1/M2/M3) or Intel processor\n• AWS CLI configured with credentials\n• Internet connection for AWS API calls"
        },
        {
          question: "How do I configure AWS credentials?",
          answer: "AWSCostMonitor uses your existing AWS CLI configuration. Set it up by:\n\n1. Install AWS CLI: `brew install awscli`\n2. Configure credentials: `aws configure`\n3. Enter your Access Key ID and Secret Access Key\n4. The app will automatically detect your profiles from ~/.aws/config"
        },
        {
          question: "Can I use IAM roles or SSO?",
          answer: "Yes! AWSCostMonitor supports:\n• IAM user credentials\n• IAM roles with assume role\n• AWS SSO/Identity Center profiles\n• MFA-protected accounts\n• Cross-account access\n\nJust configure them in your AWS CLI and they'll appear in the app."
        },
        {
          question: "The app shows 'macOS cannot verify the developer'",
          answer: "This is macOS's Gatekeeper protection. To open the app:\n\n1. Right-click the app and select 'Open'\n2. Click 'Open' in the dialog\n3. Or go to System Settings > Privacy & Security and click 'Open Anyway'\n\nThe app is safe and will be notarized by Apple soon."
        }
      ]
    },
    {
      title: "Features & Usage",
      icon: <Settings size={24} />,
      color: "tertiary",
      faqs: [
        {
          question: "How often does the app refresh cost data?",
          answer: "Refresh frequency is intelligent and budget-based:\n• Far from budget (0-50%): Every 60 minutes\n• Approaching budget (50-80%): Every 30 minutes\n• Near budget (80-95%): Every 15 minutes\n• Over budget (95%+): Every 5 minutes\n\nYou can always manually refresh with ⌘R."
        },
        {
          question: "What data does the app display?",
          answer: "The app shows comprehensive cost insights:\n• Month-to-date (MTD) spending\n• Daily cost breakdown calendar\n• Service-level cost analysis\n• Spending trends and forecasts\n• Budget progress indicators\n• Historical comparisons\n• Top expensive services\n• Cost anomaly detection"
        },
        {
          question: "Can I track multiple AWS accounts?",
          answer: "Yes! Pro version supports unlimited AWS profiles. You can:\n• Switch between profiles with ⌘1-9\n• Set different budgets per profile\n• View aggregate costs across accounts\n• Configure refresh rates per profile\n• Track API usage per profile"
        },
        {
          question: "How do keyboard shortcuts work?",
          answer: "AWSCostMonitor includes powerful shortcuts:\n• ⌘R - Refresh current profile\n• ⌘K - Toggle calendar view\n• ⌘1-9 - Quick switch profiles\n• ⌘Q - Quit application\n• ⌘, - Open preferences\n• ⌘E - Export current data"
        }
      ]
    },
    {
      title: "Troubleshooting",
      icon: <AlertTriangle size={24} />,
      color: "warning",
      faqs: [
        {
          question: "I'm getting 'Access Denied' errors",
          answer: "This means your AWS credentials lack the required permissions. Your IAM user/role needs:\n\n• `ce:GetCostAndUsage` - For cost data\n• `ce:GetCostForecast` - For predictions\n• `sts:GetCallerIdentity` - For account info\n\nAsk your AWS administrator to add the 'Billing' or 'Cost Explorer' read-only policy."
        },
        {
          question: "The app isn't showing in my menu bar",
          answer: "Try these steps:\n\n1. Check if the app is running (look in Activity Monitor)\n2. Restart the app\n3. Check System Settings > Control Center > Menu Bar Only\n4. Try resetting menu bar: `killall SystemUIServer`\n5. Ensure you have menu bar space (too many icons can hide apps)"
        },
        {
          question: "Cost data seems incorrect or outdated",
          answer: "AWS cost data can have delays:\n\n• AWS updates cost data every 8-24 hours\n• Some services report costs with up to 48-hour delay\n• Credits/refunds may take days to appear\n• Check AWS Cost Explorer to verify\n• Try manual refresh with ⌘R"
        },
        {
          question: "High API costs from the app",
          answer: "AWSCostMonitor has built-in protections:\n\n• Hard limit: 1 request per minute per profile\n• Smart caching reduces redundant calls\n• Budget-based refresh optimization\n• Typical monthly cost: $0.10-$0.50\n\nIf you see high costs, check the API counter in settings."
        }
      ]
    },
    {
      title: "Privacy & Security",
      icon: <Shield size={24} />,
      color: "success",
      faqs: [
        {
          question: "Is my AWS data secure?",
          answer: "Absolutely! AWSCostMonitor prioritizes security:\n\n• 100% local processing - no data leaves your Mac\n• No telemetry or analytics collection\n• No external servers or cloud services\n• Direct AWS API connection only\n• Credentials stored in macOS Keychain\n• Open source for transparency"
        },
        {
          question: "What permissions does the app need?",
          answer: "Minimal permissions required:\n\n• Read access to ~/.aws/config (for profiles)\n• Network access to AWS APIs only\n• Menu bar display permission\n• Optional: Notification permission for alerts\n\nNo admin rights, no system modifications."
        },
        {
          question: "Can you see my AWS costs or account info?",
          answer: "No, we cannot see any of your data:\n\n• No backend servers to send data to\n• No user accounts or registration\n• No crash reporting with personal data\n• No usage analytics or tracking\n• Everything stays on your Mac\n\nYour privacy is absolute."
        }
      ]
    }
  ]

  return (
    <div className="app">
      <GeometricShapes />
      <MemphisPatterns />
      
      <Navigation isMenuOpen={isMenuOpen} setIsMenuOpen={setIsMenuOpen} />

      {/* Hero Section */}
      <section className="hero memphis-decoration">
        <div className="memphis-hero-bg" />
        <div className="memphis-grid-overlay" />
        <div className="container">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="hero-text" style={{ maxWidth: '800px', margin: '0 auto', textAlign: 'center' }}
          >
            <div className="hero-badge">
              <span className="badge-primary">SUPPORT CENTER</span>
              <span>We're here to help</span>
            </div>
            
            <h1 className="hero-title">
              Support &
              <span className="text-gradient"> FAQ</span>
            </h1>
            
            <p className="hero-description">
              Get answers to common questions, troubleshooting help, and learn how to make the most of AWSCostMonitor.
            </p>

            {/* Important Notice */}
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.3 }}
              className="card card-brutal card-memphis"
              style={{ 
                background: 'var(--color-warning-bg)', 
                border: '3px solid var(--color-warning)',
                marginTop: '2rem',
                marginBottom: '2rem'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: '1rem' }}>
                <AlertCircle size={24} color="var(--color-warning)" />
                <div style={{ textAlign: 'left' }}>
                  <h3 style={{ marginBottom: '0.5rem', color: 'var(--color-warning)' }}>App Store Purchase Issue</h3>
                  <p style={{ marginBottom: '1rem' }}>
                    We're aware some users are experiencing "Unable to load pricing" in the App Store version. This is being actively resolved with Apple.
                  </p>
                  <p style={{ marginBottom: '0' }}>
                    <strong>Workaround:</strong> You can purchase directly from our website and download the standalone version with the same features.
                  </p>
                </div>
              </div>
            </motion.div>
            
            <div className="hero-stats">
              <div className="stat">
                <span className="stat-number">24hr</span>
                <span className="stat-label">Response Time</span>
              </div>
              <div className="stat">
                <span className="stat-number">100%</span>
                <span className="stat-label">Satisfaction</span>
              </div>
              <div className="stat">
                <span className="stat-number">Active</span>
                <span className="stat-label">Community</span>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Contact Options */}
      <section className="features pattern-dots" style={{ paddingTop: '60px', paddingBottom: '60px' }}>
        <div className="container">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="section-header"
            style={{ textAlign: 'center', marginBottom: '3rem' }}
          >
            <h2>Need Help? <span className="text-gradient">Contact Us</span></h2>
            <p>Multiple ways to get the support you need</p>
          </motion.div>
          
          <div className="features-grid" style={{ gridTemplateColumns: 'repeat(3, 1fr)' }}>
            <motion.a
              href="mailto:support@awscostmonitor.io"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="feature-card card card-brutal card-memphis card-primary"
              style={{ textDecoration: 'none', color: 'inherit' }}
            >
              <div className="feature-icon">
                <Mail size={32} />
              </div>
              <h3>Email Support</h3>
              <p>support@awscostmonitor.io</p>
              <p style={{ fontSize: '0.875rem', opacity: 0.8 }}>24-hour response time</p>
            </motion.a>
            
            <motion.a
              href="https://github.com/middleout/awscostmonitor/issues"
              target="_blank"
              rel="noopener noreferrer"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="feature-card card card-brutal card-memphis card-secondary"
              style={{ textDecoration: 'none', color: 'inherit' }}
            >
              <div className="feature-icon">
                <MessageCircle size={32} />
              </div>
              <h3>GitHub Issues</h3>
              <p>Report bugs and request features</p>
              <p style={{ fontSize: '0.875rem', opacity: 0.8 }}>Community powered</p>
            </motion.a>
            
            <motion.a
              href="https://twitter.com/awscostmonitor"
              target="_blank"
              rel="noopener noreferrer"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="feature-card card card-brutal card-memphis card-tertiary"
              style={{ textDecoration: 'none', color: 'inherit' }}
            >
              <div className="feature-icon">
                <HelpCircle size={32} />
              </div>
              <h3>Twitter/X</h3>
              <p>@awscostmonitor</p>
              <p style={{ fontSize: '0.875rem', opacity: 0.8 }}>Quick questions & updates</p>
            </motion.a>
          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <section className="faq-section pattern-squiggle" style={{ paddingTop: '60px', paddingBottom: '60px' }}>
        <div className="container">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="section-header"
            style={{ textAlign: 'center', marginBottom: '3rem' }}
          >
            <h2>Frequently Asked <span className="text-gradient">Questions</span></h2>
            <p>Everything you need to know about AWSCostMonitor</p>
          </motion.div>

          <div className="faq-categories">
            {faqCategories.map((category, categoryIndex) => (
              <motion.div
                key={categoryIndex}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ delay: categoryIndex * 0.1 }}
                viewport={{ once: true }}
                className="faq-category"
                style={{ marginBottom: '3rem' }}
              >
                <div className={`category-header card-${category.color}`} style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '1rem',
                  marginBottom: '1.5rem',
                  padding: '1rem',
                  background: `var(--color-${category.color}-light)`,
                  borderRadius: 'var(--radius-lg)',
                  border: `3px solid var(--color-${category.color})`
                }}>
                  {category.icon}
                  <h3 style={{ margin: 0 }}>{category.title}</h3>
                </div>

                <div className="faq-items">
                  {category.faqs.map((faq, faqIndex) => {
                    const globalIndex = `${categoryIndex}-${faqIndex}`
                    const isOpen = openFaq === globalIndex
                    
                    return (
                      <motion.div
                        key={faqIndex}
                        className={`faq-item card card-brutal ${faq.highlight ? 'card-memphis' : ''}`}
                        style={{ 
                          marginBottom: '1rem',
                          border: faq.highlight ? '3px solid var(--color-warning)' : undefined,
                          background: faq.highlight ? 'var(--color-warning-bg)' : undefined
                        }}
                      >
                        <button
                          className="faq-question"
                          onClick={() => toggleFaq(globalIndex)}
                          style={{
                            width: '100%',
                            textAlign: 'left',
                            padding: '1.25rem',
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            fontFamily: 'var(--font-primary)',
                            fontSize: '1.125rem',
                            fontWeight: '600',
                            color: 'var(--color-dark)'
                          }}
                        >
                          <span style={{ flex: 1, paddingRight: '1rem' }}>
                            {faq.highlight && <AlertCircle size={20} style={{ display: 'inline', marginRight: '0.5rem', color: 'var(--color-warning)' }} />}
                            {faq.question}
                          </span>
                          {isOpen ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
                        </button>
                        
                        <AnimatePresence>
                          {isOpen && (
                            <motion.div
                              initial={{ height: 0, opacity: 0 }}
                              animate={{ height: 'auto', opacity: 1 }}
                              exit={{ height: 0, opacity: 0 }}
                              transition={{ duration: 0.3 }}
                              style={{ overflow: 'hidden' }}
                            >
                              <div
                                className="faq-answer"
                                style={{
                                  padding: '0 1.25rem 1.25rem',
                                  color: 'var(--color-text)',
                                  lineHeight: '1.6',
                                  whiteSpace: 'pre-wrap'
                                }}
                              >
                                {faq.answer}
                              </div>
                            </motion.div>
                          )}
                        </AnimatePresence>
                      </motion.div>
                    )
                  })}
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Additional Resources */}
      <section className="resources pattern-grid" style={{ paddingTop: '60px', paddingBottom: '80px' }}>
        <div className="container">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="section-header"
            style={{ textAlign: 'center', marginBottom: '3rem' }}
          >
            <h2>Additional <span className="text-gradient">Resources</span></h2>
            <p>Guides, documentation, and community resources</p>
          </motion.div>

          <div className="features-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
            <motion.a
              href="/unsigned-app-guide"
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              viewport={{ once: true }}
              className="resource-card card card-brutal"
              style={{ textDecoration: 'none', color: 'inherit', textAlign: 'center', padding: '2rem 1rem' }}
            >
              <Settings size={40} style={{ marginBottom: '1rem', color: 'var(--color-primary)' }} />
              <h4>Installation Guide</h4>
              <p style={{ fontSize: '0.875rem', opacity: 0.8 }}>Step-by-step setup</p>
            </motion.a>

            <motion.a
              href="https://github.com/middleout/awscostmonitor/wiki"
              target="_blank"
              rel="noopener noreferrer"
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              viewport={{ once: true }}
              className="resource-card card card-brutal"
              style={{ textDecoration: 'none', color: 'inherit', textAlign: 'center', padding: '2rem 1rem' }}
            >
              <ExternalLink size={40} style={{ marginBottom: '1rem', color: 'var(--color-secondary)' }} />
              <h4>Documentation</h4>
              <p style={{ fontSize: '0.875rem', opacity: 0.8 }}>Full feature docs</p>
            </motion.a>

            <motion.a
              href="/changelog"
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              viewport={{ once: true }}
              className="resource-card card card-brutal"
              style={{ textDecoration: 'none', color: 'inherit', textAlign: 'center', padding: '2rem 1rem' }}
            >
              <AlertCircle size={40} style={{ marginBottom: '1rem', color: 'var(--color-tertiary)' }} />
              <h4>Changelog</h4>
              <p style={{ fontSize: '0.875rem', opacity: 0.8 }}>Latest updates</p>
            </motion.a>

            <motion.a
              href="/privacy"
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              viewport={{ once: true }}
              className="resource-card card card-brutal"
              style={{ textDecoration: 'none', color: 'inherit', textAlign: 'center', padding: '2rem 1rem' }}
            >
              <Shield size={40} style={{ marginBottom: '1rem', color: 'var(--color-success)' }} />
              <h4>Privacy Policy</h4>
              <p style={{ fontSize: '0.875rem', opacity: 0.8 }}>Your data is safe</p>
            </motion.a>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  )
}

export default Support