import { motion } from 'framer-motion'
import { AlertCircle, Shield, Settings, ChevronRight, Check, Home } from 'lucide-react'

const UnsignedAppGuide = () => {
  return (
    <div className="unsigned-guide-page">
      <div className="container">
        {/* Back to home link */}
        <a href="/" className="back-link">
          <Home size={20} />
          Back to Home
        </a>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="guide-header"
        >
          <div className="guide-icon">
            <Shield size={48} />
          </div>
          <h1>Opening an Unsigned App on macOS</h1>
          <p className="guide-subtitle">
            AWSCostMonitor is not yet code-signed, which means macOS will show a security warning when you first open it. 
            This is normal for independent apps, and here's how to safely open it.
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="warning-banner"
        >
          <AlertCircle size={24} />
          <div>
            <strong>Why does this happen?</strong>
            <p>Apple requires developers to pay for a Developer ID certificate to sign apps. As an open-source project, 
            we haven't yet obtained this certificate. The app is completely safe and its source code is publicly available on GitHub.</p>
          </div>
        </motion.div>

        <div className="guide-methods">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="method-section"
          >
            <h2>Method 1: Using System Settings (Recommended)</h2>
            
            <div className="step-card">
              <div className="step-number">1</div>
              <div className="step-content">
                <h3>Try to open the app normally</h3>
                <p>Double-click AWSCostMonitor.app. You'll see a dialog saying the app cannot be opened.</p>
                <img src="/screenshots/unsigned-dialog-1.png" alt="macOS security dialog" className="screenshot" />
                <p className="step-action">Click <strong>"Cancel"</strong> or <strong>"Done"</strong></p>
              </div>
            </div>

            <div className="step-card">
              <div className="step-number">2</div>
              <div className="step-content">
                <h3>Open System Settings</h3>
                <p>Go to <strong>Apple Menu → System Settings</strong></p>
                <img src="/screenshots/system-settings-menu.png" alt="Opening System Settings" className="screenshot" />
                <div className="keyboard-shortcut">
                  <kbd>⌘</kbd> + <kbd>Space</kbd> then type "System Settings"
                </div>
              </div>
            </div>

            <div className="step-card">
              <div className="step-number">3</div>
              <div className="step-content">
                <h3>Navigate to Privacy & Security</h3>
                <p>In the sidebar, scroll down and click <strong>Privacy & Security</strong></p>
                <img src="/screenshots/privacy-security-sidebar.png" alt="Privacy & Security in sidebar" className="screenshot" />
              </div>
            </div>

            <div className="step-card">
              <div className="step-number">4</div>
              <div className="step-content">
                <h3>Find the Security section</h3>
                <p>Scroll down to the <strong>Security</strong> section. You'll see a message about AWSCostMonitor being blocked.</p>
                <img src="/screenshots/security-section-blocked.png" alt="Security section showing blocked app" className="screenshot" />
                <p className="step-action">Click <strong>"Open Anyway"</strong></p>
              </div>
            </div>

            <div className="step-card">
              <div className="step-number">5</div>
              <div className="step-content">
                <h3>Confirm and enter password</h3>
                <p>You may be asked to enter your Mac password or use Touch ID.</p>
                <img src="/screenshots/password-prompt.png" alt="Password prompt" className="screenshot" />
              </div>
            </div>

            <div className="step-card">
              <div className="step-number">6</div>
              <div className="step-content">
                <h3>Open the app</h3>
                <p>Try opening AWSCostMonitor again. This time, you'll see a different dialog with an "Open" button.</p>
                <img src="/screenshots/final-open-dialog.png" alt="Final open dialog" className="screenshot" />
                <p className="step-action">Click <strong>"Open"</strong></p>
                <div className="success-message">
                  <Check size={20} />
                  <span>The app will now open and you won't see this warning again!</span>
                </div>
              </div>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 0.4 }}
            className="method-section alternative"
          >
            <h2>Method 2: Right-Click Method (Alternative)</h2>
            
            <div className="step-card compact">
              <div className="step-number">1</div>
              <div className="step-content">
                <h3>Right-click the app</h3>
                <p>In Finder, right-click (or Control-click) on AWSCostMonitor.app</p>
              </div>
            </div>

            <div className="step-card compact">
              <div className="step-number">2</div>
              <div className="step-content">
                <h3>Select "Open" from the menu</h3>
                <p>Choose <strong>Open</strong> from the context menu (not double-click)</p>
              </div>
            </div>

            <div className="step-card compact">
              <div className="step-number">3</div>
              <div className="step-content">
                <h3>Click "Open" in the dialog</h3>
                <p>You'll see a dialog with an "Open" button. Click it to launch the app.</p>
              </div>
            </div>
          </motion.div>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="additional-info"
        >
          <h2>Frequently Asked Questions</h2>
          
          <div className="faq-item">
            <h3>Is the app safe?</h3>
            <p>Yes! AWSCostMonitor is open-source software. You can review the entire source code on 
            <a href="https://github.com/toml0006/AWSCostMonitor" target="_blank" rel="noopener noreferrer"> GitHub</a>. 
            The warning appears because we haven't paid for an Apple Developer certificate yet.</p>
          </div>

          <div className="faq-item">
            <h3>Will I see this warning every time?</h3>
            <p>No, you only need to do this once. After you've approved the app, macOS will remember your choice.</p>
          </div>

          <div className="faq-item">
            <h3>What if I don't see "Open Anyway"?</h3>
            <p>Make sure you've tried to open the app first (Step 1). The "Open Anyway" button only appears after macOS has blocked the app at least once.</p>
          </div>

          <div className="faq-item">
            <h3>Can I verify the app myself?</h3>
            <p>Absolutely! You can build the app from source if you prefer. Check our 
            <a href="https://github.com/toml0006/AWSCostMonitor#building-from-source" target="_blank" rel="noopener noreferrer"> build instructions</a> on GitHub.</p>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.6 }}
          className="guide-footer"
        >
          <p>Still having trouble? <a href="https://github.com/toml0006/AWSCostMonitor/issues" target="_blank" rel="noopener noreferrer">Open an issue on GitHub</a> and we'll help you out!</p>
        </motion.div>
      </div>
    </div>
  )
}

export default UnsignedAppGuide