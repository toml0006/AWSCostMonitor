# Development Guide

## Quick Start

```bash
# Run setup script (recommended for new developers)
node scripts/dev-setup.js

# OR manually:
npm install
cp .env.example .env.local
npm run dev
```

## Project Structure

```
src/
├── components/          # React components
├── hooks/              # Custom React hooks
├── utils/              # Utility functions and constants
├── styles/             # CSS stylesheets
└── assets/             # Static assets
```

## Development Workflow

### 1. Component Development
- Create components in `src/components/`
- Use functional components with hooks
- Follow Memphis design principles
- Add animations with Framer Motion's `whileInView`

### 2. Styling
- Component styles go in `src/styles/components.css`
- Use CSS custom properties for consistency
- Follow the Memphis color palette and spacing

### 3. Performance
- Use `React.memo()` for expensive components
- Optimize images with proper `alt` tags and lazy loading
- Keep animations performant with `whileInView={{ once: true }}`

## Code Quality

### ESLint Rules
- Run `npm run lint` before committing
- Use `npm run lint:fix` for auto-fixable issues
- No unused variables (prefix with `_` if intentional)
- Prefer `const` over `let`, never use `var`

### Best Practices
- Keep components under 200 lines
- Extract reusable logic to custom hooks
- Use constants for magic numbers and strings
- Add JSDoc comments for complex functions

## Memphis Design System

### Colors
```css
--color-primary: #FF6B6B;     /* Coral red */
--color-secondary: #4ECDC4;   /* Teal */
--color-accent: #45B7D1;      /* Blue */
--color-warning: #F9C74F;     /* Yellow */
--color-success: #90EE90;     /* Light green */
```

### Typography
- Headings: `font-family: var(--font-primary)` (Inter)
- Body: `font-family: var(--font-secondary)` (System fonts)
- Code: `font-family: 'SF Mono', monospace`

### Spacing
- Use multiples of 0.5rem: `0.5rem`, `1rem`, `1.5rem`, `2rem`
- Border radius: `0.5rem` (8px), `1rem` (16px)
- Bold borders: `3-4px solid`

## Performance Monitoring

### Bundle Analysis
```bash
npm run analyze
```

### Key Metrics to Watch
- Bundle size (aim for < 1MB total)
- First Contentful Paint (aim for < 2s)
- Cumulative Layout Shift (aim for < 0.1)

## Deployment

### GitHub Pages
The site deploys to GitHub Pages with base path `/AWSCostMonitor/`.

### Production Build
```bash
npm run build
npm run preview  # Test production build locally
```

## Troubleshooting

### Common Issues

**Animations not working:**
- Check that Framer Motion is properly installed
- Ensure `viewport={{ once: true }}` is set for performance

**CSS not updating:**
- Hard refresh (Cmd/Ctrl + Shift + R)
- Check for CSS syntax errors in console

**Build failures:**
- Run `npm run clean && npm run build`
- Check for unused imports or exports

### Getting Help
- Check the main README for project overview
- Review component examples in `src/components/`
- Look at utility functions in `src/utils/`

## Future Improvements

- [ ] Add TypeScript for better type safety
- [ ] Implement Prettier for consistent formatting
- [ ] Add Storybook for component documentation
- [ ] Set up automated testing with Vitest
- [ ] Add bundle size monitoring in CI