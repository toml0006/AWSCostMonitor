import { Shield, Lock, Eye, Server, Cloud, Database, Key, UserX } from 'lucide-react'
import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'

function Privacy() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-gray-900/80 backdrop-blur-lg border-b border-gray-800">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <Link to="/" className="flex items-center gap-2 text-white hover:text-purple-400 transition-colors">
              <Cloud className="w-6 h-6" />
              <span className="font-bold text-xl">AWSCostMonitor</span>
            </Link>
            <Link to="/" className="text-gray-400 hover:text-white transition-colors">
              Back to Home
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-6">
        <div className="container mx-auto max-w-4xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center mb-16"
          >
            <div className="inline-flex items-center justify-center w-20 h-20 bg-purple-600/20 rounded-full mb-6">
              <Shield className="w-10 h-10 text-purple-400" />
            </div>
            <h1 className="text-5xl font-bold text-white mb-6">Privacy Policy</h1>
            <p className="text-xl text-gray-400">Your privacy is our priority. Here's how we protect it.</p>
            <p className="text-sm text-gray-500 mt-2">Last Updated: August 16, 2025</p>
          </motion.div>

          {/* Privacy Highlights */}
          <div className="grid md:grid-cols-3 gap-6 mb-16">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="bg-gradient-to-br from-red-600 to-pink-600 p-6 rounded-xl text-white text-center"
            >
              <UserX className="w-8 h-8 mx-auto mb-3" />
              <h3 className="font-bold text-lg mb-2">No Data Collection</h3>
              <p className="text-sm opacity-90">We don't collect, store, or transmit any of your data</p>
            </motion.div>
            
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="bg-gradient-to-br from-blue-600 to-cyan-600 p-6 rounded-xl text-white text-center"
            >
              <Database className="w-8 h-8 mx-auto mb-3" />
              <h3 className="font-bold text-lg mb-2">100% Local</h3>
              <p className="text-sm opacity-90">Everything runs on your Mac - no external servers</p>
            </motion.div>
            
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="bg-gradient-to-br from-green-600 to-emerald-600 p-6 rounded-xl text-white text-center"
            >
              <Key className="w-8 h-8 mx-auto mb-3" />
              <h3 className="font-bold text-lg mb-2">Your AWS, Your Control</h3>
              <p className="text-sm opacity-90">Direct connection to AWS - we never see your credentials</p>
            </motion.div>
          </div>

          {/* Privacy Content */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.4 }}
            className="prose prose-lg prose-invert max-w-none"
          >
            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-8 mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-3">
                <Lock className="w-6 h-6 text-purple-400" />
                How AWSCostMonitor Works
              </h2>
              
              <h3 className="text-xl font-semibold text-white mt-6 mb-3">Local-Only Architecture</h3>
              <ul className="space-y-2 text-gray-300">
                <li>• <strong>No telemetry</strong> - We don't track usage or collect analytics</li>
                <li>• <strong>No phone home</strong> - The app never contacts our servers (we don't have any!)</li>
                <li>• <strong>No accounts</strong> - No registration or sign-up required</li>
                <li>• <strong>No ads</strong> - No advertising or tracking mechanisms</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">AWS Credentials Management</h3>
              <ul className="space-y-2 text-gray-300">
                <li>• Read from your existing AWS CLI configuration</li>
                <li>• Never transmitted to us or any third party</li>
                <li>• Used only for direct API calls from your Mac to AWS</li>
                <li>• Managed by macOS's secure system configuration</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">Data Flow</h3>
              <div className="bg-gray-900/50 p-4 rounded-lg font-mono text-sm text-green-400">
                Your Mac → AWS Cost Explorer API → Cost Data → Display in Menu Bar
              </div>
              <p className="text-gray-400 mt-2">That's it. No detours. No middleman. Just direct, secure communication.</p>
            </div>

            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-8 mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-3">
                <Server className="w-6 h-6 text-purple-400" />
                What We Don't Do
              </h2>
              <div className="grid md:grid-cols-2 gap-4">
                <ul className="space-y-2 text-gray-300">
                  <li>❌ No user tracking</li>
                  <li>❌ No usage analytics</li>
                  <li>❌ No error reporting to us</li>
                  <li>❌ No crash analytics</li>
                </ul>
                <ul className="space-y-2 text-gray-300">
                  <li>❌ No behavioral data</li>
                  <li>❌ No marketing data</li>
                  <li>❌ No data selling</li>
                  <li>❌ No third-party sharing</li>
                </ul>
              </div>
            </div>

            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-8 mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-3">
                <Cloud className="w-6 h-6 text-purple-400" />
                Optional Team Cache Feature
              </h2>
              <p className="text-gray-300 mb-4">If you choose to enable Team Cache:</p>
              <ul className="space-y-2 text-gray-300">
                <li>• Data is stored in <strong>your own AWS S3 bucket</strong></li>
                <li>• You specify the bucket and control access</li>
                <li>• Only team members with access to that bucket can share data</li>
                <li>• We have no visibility into this data</li>
                <li>• Everything stays within your AWS infrastructure</li>
              </ul>
            </div>

            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-8 mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-3">
                <Eye className="w-6 h-6 text-purple-400" />
                Open Source Transparency
              </h2>
              <p className="text-gray-300 mb-4">AWSCostMonitor is open source. You can:</p>
              <ul className="space-y-2 text-gray-300">
                <li>• Review our code on <a href="https://github.com/toml0006/AWSCostMonitor" className="text-purple-400 hover:text-purple-300">GitHub</a></li>
                <li>• Verify our privacy claims</li>
                <li>• Build it yourself from source</li>
                <li>• Contribute improvements</li>
              </ul>
            </div>

            <div className="bg-gradient-to-r from-purple-600/20 to-pink-600/20 border border-purple-500/30 rounded-xl p-8 text-center">
              <h2 className="text-2xl font-bold text-white mb-4">Privacy Promise</h2>
              <p className="text-lg text-gray-300">
                <strong>Your AWS cost data is yours alone.</strong><br />
                We can't see it, we don't want to see it, and we've built AWSCostMonitor to ensure it stays that way.
              </p>
            </div>

            <div className="mt-12 text-center text-gray-400">
              <p className="mb-4">Questions about privacy?</p>
              <div className="flex justify-center gap-4">
                <a href="https://github.com/toml0006/AWSCostMonitor/issues" className="text-purple-400 hover:text-purple-300">
                  Report an Issue
                </a>
                <span>•</span>
                <Link to="/" className="text-purple-400 hover:text-purple-300">
                  Back to Home
                </Link>
              </div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  )
}

export default Privacy