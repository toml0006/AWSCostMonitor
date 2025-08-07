/**
 * Environment configuration and feature flags
 * Centralized place to manage environment variables
 */

// App configuration from environment
export const ENV_CONFIG = {
  APP_TITLE: import.meta.env.VITE_APP_TITLE || 'AWS Cost Monitor',
  APP_VERSION: import.meta.env.VITE_APP_VERSION || '1.0.0',
  IS_DEVELOPMENT: import.meta.env.DEV,
  IS_PRODUCTION: import.meta.env.PROD
}

// Feature flags for conditional rendering
export const FEATURE_FLAGS = {
  SHOW_DEBUG_INFO: import.meta.env.VITE_SHOW_DEBUG_INFO === 'true',
  ENABLE_ANIMATIONS: import.meta.env.VITE_ENABLE_ANIMATIONS !== 'false', // Default true
  MOCK_SCREENSHOTS: import.meta.env.VITE_MOCK_SCREENSHOTS === 'true'
}

// Development helpers
export const isDevelopment = () => ENV_CONFIG.IS_DEVELOPMENT
export const isProduction = () => ENV_CONFIG.IS_PRODUCTION

/**
 * Conditionally log messages only in development
 * @param  {...any} args - Arguments to console.log
 */
export const devLog = (...args) => {
  if (isDevelopment()) {
    console.log('[DEV]', ...args)
  }
}

/**
 * Conditionally warn messages only in development
 * @param  {...any} args - Arguments to console.warn
 */
export const devWarn = (...args) => {
  if (isDevelopment()) {
    console.warn('[DEV]', ...args)
  }
}

/**
 * Get environment-specific URL or fallback
 * @param {string} envVar - Environment variable name
 * @param {string} fallback - Fallback URL
 * @returns {string} URL to use
 */
export const getEnvUrl = (envVar, fallback) => {
  return import.meta.env[envVar] || fallback
}