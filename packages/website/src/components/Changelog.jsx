import { motion } from 'framer-motion'
import { 
  Calendar,
  Sparkles,
  Bug,
  Zap,
  Shield,
  BarChart3,
  PieChart,
  Eye,
  TrendingUp,
  Users,
  Bell,
  Lock,
  RefreshCw,
  MousePointer,
  Palette,
  CheckCircle,
  ArrowRight
} from 'lucide-react'

const releases = [
  {
    version: '1.3.2',
    date: 'August 19, 2025',
    title: 'Team Collaboration & Visual Refresh',
    icon: Users,
    color: 'primary',
    highlights: [
      'Team Remote Caching with S3 for shared cost data',
      'New professional app icons with modern design',
      'Comprehensive team cache setup documentation',
      'Enhanced timer reliability for consistent updates'
    ],
    features: [
      {
        icon: Users,
        title: 'Team Remote Caching',
        description: 'Share cost data across your team using S3 to dramatically reduce API calls and costs'
      },
      {
        icon: Sparkles,
        title: 'Professional New Icons',
        description: 'Complete visual redesign with modern, polished app icons'
      },
      {
        icon: RefreshCw,
        title: 'Improved Timer System',
        description: 'Fixed refresh timer using Timer.scheduledTimer for reliable updates'
      }
    ],
    improvements: [
      'Comprehensive team cache setup guide with step-by-step instructions',
      'Enhanced S3 integration for team data sharing',
      'Improved error handling for cache operations',
      'Privacy-first approach maintained with no third-party services'
    ]
  },
  {
    version: '1.3.0',
    date: 'August 14, 2025',
    title: 'Smart Profile Management & Intelligent Filtering',
    icon: RefreshCw,
    color: 'secondary',
    highlights: [
      'Choose which AWS profiles appear in dropdowns',
      'Automatic detection of new and removed profiles',
      'Preserve data for removed profiles with view-only access',
      'Smart prompts for profile changes on startup'
    ],
    features: [
      {
        icon: Users,
        title: 'Profile Selection Management',
        description: 'Control which AWS profiles appear in dropdowns through the settings panel for a cleaner experience'
      },
      {
        icon: Bell,
        title: 'Smart Profile Detection',
        description: 'Automatically detect new profiles and prompt to add them, handle removed profiles intelligently'
      },
      {
        icon: Eye,
        title: 'Preserved Profile History',
        description: 'Keep data for removed profiles with "(removed)" suffix - view historical costs even after profile cleanup'
      }
    ],
    improvements: [
      'Enhanced settings panel with dedicated profile management section',
      'Intelligent startup scanning for AWS configuration changes',
      'Graceful handling of profile lifecycle management',
      'Preserved historical data maintains cost tracking continuity'
    ]
  },
  {
    version: '1.2.1',
    date: 'December 13, 2024',
    title: 'Interactive Histograms & UI Polish',
    icon: MousePointer,
    color: 'accent',
    highlights: [
      'Click any histogram bar for instant daily cost breakdown',
      'Smooth hover effects and cursor changes everywhere',
      'Button highlighting for better visual feedback',
      'Auto-close detail windows when menu loses focus'
    ],
    features: [
      {
        icon: BarChart3,
        title: 'Interactive Histogram Bars',
        description: 'Click any histogram bar to instantly see a detailed daily cost breakdown with all services'
      },
      {
        icon: Palette,
        title: 'Enhanced Visual Feedback',
        description: 'Every clickable element now provides immediate visual feedback with smooth animations'
      },
      {
        icon: MousePointer,
        title: 'Improved Cursor States',
        description: 'Pointing hand cursor on all interactive elements for better discoverability'
      }
    ],
    bugFixes: [
      'Fixed day detail window not loading on first click',
      'Detail windows now properly close when menu loses focus',
      'Eliminated lag in sheet presentations',
      'Improved state management for modal windows'
    ]
  },
  {
    version: '1.2.0',
    date: 'December 12, 2024',
    title: 'Calendar View & Professional Visualizations',
    icon: Calendar,
    color: 'primary',
    highlights: [
      'Beautiful monthly calendar with color-coded spending',
      'Interactive donut charts with hover effects',
      'Service-level histogram visualizations',
      'Keyboard shortcuts for power users'
    ],
    features: [
      {
        icon: Calendar,
        title: 'Monthly Calendar View',
        description: 'Visualize your AWS spending patterns with a beautiful calendar showing daily costs with color intensity'
      },
      {
        icon: PieChart,
        title: 'Interactive Donut Charts',
        description: 'Professional charts with smooth hover effects showing service cost breakdowns'
      },
      {
        icon: BarChart3,
        title: 'Service Histograms',
        description: '14-day spending trends per service with intelligent color coding vs last month'
      },
      {
        icon: Zap,
        title: 'Keyboard Shortcuts',
        description: '⌘K for calendar, ⌘R for refresh, ⌘1-9 for quick profile switching'
      }
    ],
    improvements: [
      'Refactored to MVC architecture for better maintainability',
      'Added debug timer controls for testing',
      'Improved error handling and recovery',
      'Enhanced visual hierarchy throughout the app'
    ]
  },
  {
    version: '1.0.0',
    date: 'August 5, 2024',
    title: 'The Beginning - Your AWS Costs, Always Visible',
    icon: Eye,
    color: 'tertiary',
    highlights: [
      'Menu bar app for instant cost visibility',
      'Multi-profile AWS account support',
      'Smart refresh rates based on budgets',
      'Complete privacy - no data leaves your Mac'
    ],
    features: [
      {
        icon: Eye,
        title: 'Always Visible Costs',
        description: 'Live in your menu bar with instant access to AWS spending without context switching'
      },
      {
        icon: TrendingUp,
        title: 'Smart Projections',
        description: 'Month-end spending projections and percentage comparisons to last month'
      },
      {
        icon: Users,
        title: 'Multi-Profile Support',
        description: 'Seamlessly switch between multiple AWS accounts with persistent selection'
      },
      {
        icon: Bell,
        title: 'Budget Alerts',
        description: 'Get notified before exceeding monthly spending limits'
      },
      {
        icon: RefreshCw,
        title: 'Intelligent Refresh',
        description: 'Automatically adjusts polling frequency based on spending patterns'
      },
      {
        icon: Lock,
        title: 'Privacy First',
        description: 'Zero telemetry, no external servers - your data never leaves your Mac'
      }
    ],
    techStack: [
      'Native SwiftUI for macOS',
      'AWS SDK for Swift',
      'Local-only data storage',
      'Minimal resource usage'
    ]
  }
]

const Changelog = () => {
  return (
    <section className="changelog pattern-dots">
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="section-header"
        >
          <h1>Changelog</h1>
          <p>Every update brings new ways to control your AWS costs</p>
        </motion.div>

        <div className="releases-timeline">
          {releases.map((release, index) => (
            <motion.div
              key={release.version}
              id={`v${release.version.replace(/\./g, '-')}`}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className={`release-card card card-brutal card-memphis card-${release.color}`}
            >
              <div className="release-header">
                <div className="release-version">
                  <release.icon size={32} />
                  <div>
                    <h2>Version {release.version}</h2>
                    <span className="release-date">{release.date}</span>
                  </div>
                </div>
                <h3 className="release-title">{release.title}</h3>
              </div>

              <div className="release-highlights">
                <h4><Sparkles size={20} /> Highlights</h4>
                <ul>
                  {release.highlights.map((highlight, i) => (
                    <motion.li
                      key={i}
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.1 + i * 0.05 }}
                    >
                      <ArrowRight size={16} />
                      {highlight}
                    </motion.li>
                  ))}
                </ul>
              </div>

              <div className="release-features">
                <h4><Zap size={20} /> New Features</h4>
                <div className="features-list">
                  {release.features.map((feature, i) => (
                    <motion.div
                      key={i}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: index * 0.1 + i * 0.05 }}
                      className="feature-item"
                    >
                      <div className="feature-icon-small">
                        <feature.icon size={24} />
                      </div>
                      <div>
                        <h5>{feature.title}</h5>
                        <p>{feature.description}</p>
                      </div>
                    </motion.div>
                  ))}
                </div>
              </div>

              {release.bugFixes && (
                <div className="release-fixes">
                  <h4><Bug size={20} /> Bug Fixes</h4>
                  <ul>
                    {release.bugFixes.map((fix, i) => (
                      <motion.li
                        key={i}
                        initial={{ opacity: 0, x: -10 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.1 + i * 0.05 }}
                      >
                        <CheckCircle size={16} />
                        {fix}
                      </motion.li>
                    ))}
                  </ul>
                </div>
              )}

              {release.improvements && (
                <div className="release-improvements">
                  <h4><TrendingUp size={20} /> Improvements</h4>
                  <ul>
                    {release.improvements.map((improvement, i) => (
                      <motion.li
                        key={i}
                        initial={{ opacity: 0, x: -10 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.1 + i * 0.05 }}
                      >
                        <CheckCircle size={16} />
                        {improvement}
                      </motion.li>
                    ))}
                  </ul>
                </div>
              )}

              {release.techStack && (
                <div className="release-tech">
                  <h4><Shield size={20} /> Technical Foundation</h4>
                  <div className="tech-tags">
                    {release.techStack.map((tech, i) => (
                      <motion.span
                        key={i}
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: index * 0.1 + i * 0.05 }}
                        className="tech-tag"
                      >
                        {tech}
                      </motion.span>
                    ))}
                  </div>
                </div>
              )}

              <div className="release-footer">
                <a 
                  href={`https://github.com/toml0006/AWSCostMonitor/releases/tag/v${release.version}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="release-link"
                >
                  View on GitHub <ArrowRight size={16} />
                </a>
              </div>
            </motion.div>
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="changelog-cta"
        >
          <h3>Ready to take control of your AWS costs?</h3>
          <p>Download the latest version and start saving today</p>
          <a 
            href="https://github.com/toml0006/AWSCostMonitor/releases/latest"
            className="btn btn-primary btn-brutal"
          >
            <Sparkles size={20} />
            Download Latest Version
          </a>
        </motion.div>
      </div>
    </section>
  )
}

export default Changelog