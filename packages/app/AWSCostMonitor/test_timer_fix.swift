#!/usr/bin/swift

import Foundation

// Simple test to verify the async timer pattern works correctly
print("=== Testing Async Timer Pattern ===\n")

class TimerTester {
    private var timerTask: Task<Void, Never>?
    private var isRunning = false
    private var tickCount = 0
    
    func startTimer(interval: TimeInterval) {
        print("Starting async timer with \(Int(interval)) second interval...")
        
        isRunning = true
        tickCount = 0
        
        timerTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled && self.isRunning {
                do {
                    // Sleep for the interval duration
                    try await Task.sleep(for: .seconds(interval))
                    
                    // Check if we're still supposed to be running
                    guard !Task.isCancelled && self.isRunning else { break }
                    
                    self.tickCount += 1
                    print("✅ Timer tick #\(self.tickCount) at \(Date())")
                    
                    // Stop after 3 ticks for this test
                    if self.tickCount >= 3 {
                        print("🛑 Stopping timer after 3 ticks")
                        self.stopTimer()
                        break
                    }
                } catch {
                    if error is CancellationError {
                        print("⚠️ Timer was cancelled")
                        break
                    } else {
                        print("❌ Timer error: \(error)")
                        break
                    }
                }
            }
            
            print("🏁 Timer task ended")
        }
    }
    
    func stopTimer() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        print("🛑 Timer stopped")
    }
}

// Test the timer
let tester = TimerTester()
tester.startTimer(interval: 2.0) // 2 second intervals

// Keep the script running for a bit to see the timer work
print("Waiting for timer to run...")

// Use RunLoop to keep the script alive
let runLoop = RunLoop.current
let future = Date().addingTimeInterval(10.0) // Run for 10 seconds max

while runLoop.run(mode: .default, before: future) && Date() < future {
    // Keep running
}

print("\n=== Test completed ===")