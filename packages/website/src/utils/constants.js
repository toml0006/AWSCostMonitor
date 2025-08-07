// Application Constants
export const APP_CONFIG = {
  name: 'AWS Cost Monitor',
  version: '1.0.0',
  repository: 'https://github.com/your-username/AWSCostMonitor',
  minMacOSVersion: '13.0+'
}

// API Cost Information
export const AWS_API_COSTS = {
  costExplorerPerRequest: 0.01,
  maxRequestsPerMinute: 1,
  maxMonthlyRequests: 43200, // 30 days * 24 hours * 60 minutes
  maxMonthlyCost: 432.00,     // $0.01 * 43,200 requests
  typicalMonthlyCost: {
    min: 0.50,
    max: 2.00
  }
}

// Animation Variants for Framer Motion
export const ANIMATION_VARIANTS = {
  fadeInUp: {
    initial: { opacity: 0, y: 20 },
    whileInView: { opacity: 1, y: 0 },
    transition: { duration: 0.5 },
    viewport: { once: true }
  },
  
  fadeInLeft: {
    initial: { opacity: 0, x: -20 },
    whileInView: { opacity: 1, x: 0 },
    transition: { duration: 0.5 },
    viewport: { once: true }
  },
  
  fadeInRight: {
    initial: { opacity: 0, x: 20 },
    whileInView: { opacity: 1, x: 0 },
    transition: { duration: 0.5 },
    viewport: { once: true }
  },
  
  staggerContainer: {
    initial: {},
    whileInView: {
      transition: {
        staggerChildren: 0.1
      }
    },
    viewport: { once: true }
  }
}

// Navigation Menu Items
export const NAV_ITEMS = [
  { href: '#features', label: 'Features' },
  { href: '#screenshots', label: 'Screenshots' },
  { href: '#installation', label: 'Get Started' },
  { href: '#how-it-works', label: 'How It Works' },
  { href: '#pricing', label: 'Pricing' }
]

// External Links
export const EXTERNAL_LINKS = {
  awsCLIInstall: 'https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html',
  awsCLIConfig: 'https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html',
  costExplorerPermissions: 'https://docs.aws.amazon.com/cost-management/latest/userguide/ce-access.html'
}

// Required AWS Permissions
export const AWS_PERMISSIONS = [
  'ce:GetCostAndUsage',
  'ce:GetUsageReport'
]

// Feature Categories
export const FEATURE_CATEGORIES = {
  CORE: 'core',
  CONFIGURATION: 'configuration', 
  SAFETY: 'safety'
}