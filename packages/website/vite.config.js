import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/AWSCostMonitor/',
  
  // Performance optimizations
  build: {
    // Enable gzip compression for better loading
    reportCompressedSize: true,
    
    // Optimize chunk splitting for better caching
    rollupOptions: {
      output: {
        manualChunks: {
          // Separate vendor libraries for better caching
          vendor: ['react', 'react-dom'],
          animations: ['framer-motion'],
          icons: ['lucide-react']
        }
      }
    }
  },
  
  // Path resolution for cleaner imports
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@components': resolve(__dirname, './src/components'),
      '@utils': resolve(__dirname, './src/utils'),
      '@hooks': resolve(__dirname, './src/hooks'),
      '@styles': resolve(__dirname, './src/styles'),
      '@assets': resolve(__dirname, './src/assets')
    }
  },
  
  // Development server optimizations
  server: {
    // Enable Hot Module Replacement for better DX
    hmr: true,
    
    // Open browser automatically
    open: true,
    
    // Custom port (optional, falls back to 5173)
    port: 3000
  },
  
  // CSS optimizations
  css: {
    devSourcemap: true
  }
})
