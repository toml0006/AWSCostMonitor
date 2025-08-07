#!/usr/bin/env node

/**
 * Development setup script
 * Helps new developers get started quickly
 */

import { execSync } from 'child_process'
import { existsSync, copyFileSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const projectRoot = join(__dirname, '..')

console.log('🚀 Setting up AWSCostMonitor website for development...\n')

// Check if .env.local exists, create from example if not
const envPath = join(projectRoot, '.env.local')
const envExamplePath = join(projectRoot, '.env.example')

if (!existsSync(envPath) && existsSync(envExamplePath)) {
  console.log('📁 Creating .env.local from .env.example...')
  copyFileSync(envExamplePath, envPath)
  console.log('✅ .env.local created\n')
} else if (existsSync(envPath)) {
  console.log('✅ .env.local already exists\n')
}

// Install dependencies if node_modules doesn't exist
const nodeModulesPath = join(projectRoot, 'node_modules')
if (!existsSync(nodeModulesPath)) {
  console.log('📦 Installing dependencies...')
  execSync('npm install', { stdio: 'inherit', cwd: projectRoot })
  console.log('✅ Dependencies installed\n')
} else {
  console.log('✅ Dependencies already installed\n')
}

// Run a quick lint check
console.log('🔍 Running linting check...')
try {
  execSync('npm run lint', { stdio: 'inherit', cwd: projectRoot })
  console.log('✅ Linting passed\n')
} catch (error) {
  console.log('⚠️  Linting issues found (run `npm run lint:fix` to auto-fix)\n')
}

console.log('🎉 Setup complete! You can now run:')
console.log('  npm run dev     - Start development server')
console.log('  npm run build   - Build for production')
console.log('  npm run preview - Preview production build')
console.log('  npm run lint    - Check code quality')
console.log('\n✨ Happy coding!')