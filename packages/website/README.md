# AWSCostMonitor Marketing Website

A modern, Memphis design-inspired marketing website built with React + Vite for the AWSCostMonitor macOS application.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run linting
npm run lint
```

## 🏗️ Project Structure

```
src/
├── components/           # React components
│   ├── Hero.jsx         # Landing hero section
│   ├── Features.jsx     # Features showcase
│   ├── Screenshots.jsx  # Interactive screenshots gallery
│   ├── Installation.jsx # Installation guide with API cost info
│   ├── HowItWorks.jsx   # Process explanation
│   ├── Pricing.jsx      # Pricing information
│   ├── Navigation.jsx   # Main navigation
│   ├── Footer.jsx       # Site footer
│   ├── GeometricShapes.jsx   # Background geometric elements
│   └── MemphisPatterns.jsx   # Memphis design patterns
├── styles/              # CSS stylesheets
│   ├── components.css   # Component-specific styles
│   └── memphis.css      # Memphis design system
├── assets/              # Static assets
│   └── images/          # Image assets
├── App.jsx              # Main app component
├── App.css              # Global app styles
├── index.css            # Root styles and CSS variables
└── main.jsx             # React entry point
```

## 🎨 Design System

This site uses a Memphis design aesthetic with:
- Bold geometric shapes and patterns
- Bright, contrasting colors
- Playful typography
- Interactive animations via Framer Motion

### Key Design Tokens
- Primary Color: `#FF6B6B` (Coral red)
- Secondary Color: `#4ECDC4` (Teal)
- Background: `#FFF8E7` (Warm white)
- Text: `#2C3E50` (Dark blue-gray)

## 📱 Components Guide

### Interactive Components

**Screenshots.jsx**
- Tabbed interface for app screenshots
- Automatic fallback for missing images
- Animated transitions between tabs

**Installation.jsx** 
- Step-by-step installation guide
- AWS CLI integration instructions
- Cost transparency with API usage info
- Privacy and security benefits

### Design Components

**GeometricShapes.jsx** & **MemphisPatterns.jsx**
- Animated background elements
- CSS-only implementation for performance
- Responsive positioning

## 🔧 Development

### Adding New Components

1. Create component in `src/components/`
2. Add corresponding styles in `src/styles/components.css`
3. Import and use in `App.jsx`

### Memphis Design Guidelines

- Use bold, geometric shapes
- Bright, contrasting colors
- 3-4px borders for emphasis
- Rounded corners (8px, 16px)
- Playful but functional animations

### Performance Considerations

- Images lazy load with fallbacks
- Animations use `whileInView` for performance
- CSS variables for consistent theming
- Minimal bundle size with tree-shaking

## 📦 Dependencies

### Core
- **React 19.1.0** - UI framework
- **Vite 7.0.6** - Build tool and dev server
- **framer-motion 12.23.12** - Animations
- **lucide-react 0.536.0** - Icons

### Development
- **ESLint** - Code linting
- **@vitejs/plugin-react** - React support for Vite

## 🚀 Deployment

This site is configured for GitHub Pages deployment:
- Base path: `/AWSCostMonitor/`
- Static assets served from `public/`
- Production builds in `dist/`

## 🤝 Contributing

1. Follow the existing Memphis design patterns
2. Add component documentation for complex features
3. Test responsive behavior on mobile
4. Run `npm run lint` before committing
5. Keep animations performant with `whileInView`

## 📋 TODO

- [ ] Add real screenshots when app is ready
- [ ] Implement dark mode toggle
- [ ] Add proper meta tags for SEO
- [ ] Consider adding TypeScript for better DX