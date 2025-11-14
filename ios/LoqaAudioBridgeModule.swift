import AVFoundation
import ExpoModulesCore
import UIKit

/// Configuration for audio streaming session
struct StreamConfig: Record {
    @Field var sampleRate: Int = 16000
    @Field var bufferSize: Int = 2048
    @Field var channels: Int = 1
    @Field var vadEnabled: Bool = true
    @Field var adaptiveProcessing: Bool = true
}

/// Error codes for stream errors
enum StreamErrorCode: String {
    case sessionConfigFailed = "SESSION_CONFIG_FAILED"
    case engineStartFailed = "ENGINE_START_FAILED"
    case deviceNotAvailable = "DEVICE_NOT_AVAILABLE"
    case bufferOverflow = "BUFFER_OVERFLOW"
}

/// Buffer pool to reuse Float arrays and reduce allocations
class BufferPool {
    private var pool: [[Float]] = []
    private let maxSize: Int
    private let bufferSize: Int

    init(bufferSize: Int, maxSize: Int = 5) {
        self.bufferSize = bufferSize
        self.maxSize = maxSize

        // Pre-allocate initial pool
        for _ in 0..<3 {
            pool.append([Float](repeating: 0, count: bufferSize))
        }
    }

    func acquire() -> [Float] {
        if pool.isEmpty {
            return [Float](repeating: 0, count: bufferSize)
        } else {
            return pool.removeLast()
        }
    }

    func release(_ buffer: [Float]) {
        if pool.count < maxSize {
            pool.append(buffer)
        }
    }
}

/// LoqaAudioBridge Expo Module - v0.3.0 Streaming Support
/// Provides real-time audio streaming from device microphone using AVAudioEngine
public class LoqaAudioBridgeModule: Module {
    // MARK: - Properties

    /// Audio engine for capturing microphone input
    private var audioEngine: AVAudioEngine?

    /// Input node from the audio engine
    private var inputNode: AVAudioInputNode?

    /// Audio session for managing audio configuration
    private var audioSession: AVAudioSession?

    /// Timestamp tracking (milliseconds since stream start)
    private var streamStartTime: Date?

    /// Config stored for resuming after interruption
    private var currentConfig: StreamConfig?

    /// Actual sample rate used (may differ from requested if fallback occurred)
    private var actualSampleRate: Int = 16000

    /// Supported sample rates for iOS (AVAudioEngine)
    private let supportedSampleRates = [8000, 16000, 22050, 44100, 48000]

    /// Cached battery level status
    private var isLowBatteryMode: Bool = false

    /// Frame counter for adaptive processing
    private var frameCounter: Int = 0

    /// Battery optimization notification flag
    private var batteryOptimizationNotified: Bool = false

    /// Buffer pool for reusing sample arrays
    private var bufferPool: BufferPool?

    // MARK: - Lifecycle

    public required override init(appContext: AppContext) {
        super.init(appContext: appContext)

        // Register for audio session interruption notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)

        // Clean up resources
        cleanup()
    }

    // MARK: - Module Definition

    public func definition() -> ModuleDefinition {
        Name("LoqaAudioBridge")

        // Event definitions
        Events(
            "onAudioSamples",
            "onStreamError",
            "onStreamStatusChange"
        )

        // MARK: - Streaming Functions (v0.3.0)

        /// Start audio streaming with specified configuration
        AsyncFunction("startAudioStream") { (config: StreamConfig) -> Bool in
            do {
                // Store config for potential resume after interruption
                self.currentConfig = config

                // Configure audio session
                try self.configureAudioSession()

                // Setup audio engine
                try self.setupAudioEngine(config: config)

                // Install tap to capture audio buffers
                try self.installAudioTap(config: config)

                // Start the audio engine
                try self.audioEngine?.start()

                // Record start time for timestamp calculation
                self.streamStartTime = Date()

                // Check battery level and cache the result
                self.isLowBatteryMode = self.isLowBattery()

                // Emit status change event
                self.sendEvent("onStreamStatusChange", [
                    "status": "streaming",
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                    "platform": "ios"
                ])

                return true

            } catch let error as NSError {
                // Emit error event
                let errorCode = self.mapErrorToCode(error)
                self.sendEvent("onStreamError", [
                    "error": errorCode.rawValue,
                    "message": error.localizedDescription,
                    "platform": "ios",
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
                ])

                return false
            }
        }

        /// Stop audio streaming and clean up resources
        Function("stopAudioStream") { () -> Bool in
            self.cleanup()

            // Emit status change event
            self.sendEvent("onStreamStatusChange", [
                "status": "stopped",
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "platform": "ios"
            ])

            return true
        }

        /// Check if audio streaming is currently active
        Function("isStreaming") { () -> Bool in
            return self.audioEngine?.isRunning ?? false
        }

        // MARK: - Analysis Functions (v0.1.0 - from loqa-voice-dsp)
        // These functions will be integrated when linking with the Rust FFI library

        // Future: computeFFT, detectPitch, extractFormants
        // For now, focused on streaming infrastructure
    }

    // MARK: - Private Helper Functions

    /// Configure AVAudioSession for recording
    private func configureAudioSession() throws {
        audioSession = AVAudioSession.sharedInstance()

        guard let session = audioSession else {
            throw NSError(
                domain: "LoqaAudioBridge",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get audio session"]
            )
        }

        // Set category: .record (input-only)
        // Mode: .measurement (minimal processing for accurate capture)
        // Options: .allowBluetoothA2DP (support Bluetooth microphones like AirPods)
        try session.setCategory(
            .record,
            mode: .measurement,
            options: [.allowBluetoothA2DP]
        )

        // Activate the audio session
        try session.setActive(true, options: [])
    }

    /// Setup AVAudioEngine with specified configuration
    private func setupAudioEngine(config: StreamConfig) throws {
        audioEngine = AVAudioEngine()

        guard let engine = audioEngine else {
            throw NSError(
                domain: "LoqaAudioBridge",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAudioEngine"]
            )
        }

        // Get input node (represents the microphone)
        inputNode = engine.inputNode

        // Determine actual sample rate (with fallback if needed)
        actualSampleRate = findClosestSupportedRate(requested: config.sampleRate)

        if actualSampleRate != config.sampleRate {
            // Log warning about sample rate fallback
            print("[LoqaAudioBridge] Warning: Requested sample rate \(config.sampleRate) Hz not supported. Using fallback rate \(actualSampleRate) Hz instead.")
        }

        // Initialize buffer pool for sample conversion
        bufferPool = BufferPool(bufferSize: config.bufferSize, maxSize: 5)

        // Log buffer stats
        let bufferDuration = Double(config.bufferSize) / Double(actualSampleRate) * 1000.0
        print("[LoqaAudioBridge] Buffer stats: sampleRate=\(actualSampleRate) Hz, bufferSize=\(config.bufferSize) samples, bufferDuration=\(String(format: "%.1f", bufferDuration)) ms")
    }

    /// Install tap on input node to capture audio buffers
    private func installAudioTap(config: StreamConfig) throws {
        guard let inputNode = inputNode else {
            throw NSError(
                domain: "LoqaAudioBridge",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "Input node not available"]
            )
        }

        // Create audio format: Float32, actual sample rate (with fallback), mono, non-interleaved
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(actualSampleRate),
            channels: AVAudioChannelCount(config.channels),
            interleaved: false
        ) else {
            throw NSError(
                domain: "LoqaAudioBridge",
                code: 1004,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create audio format"]
            )
        }

        // Install tap on bus 0 with specified buffer size and format
        inputNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(config.bufferSize),
            format: format
        ) { [weak self, config] (buffer, time) in
            guard let self = self else { return }

            // Wrap in autoreleasepool to reduce temporary allocations
            autoreleasepool {
                // Track execution time for overflow detection
                let startTime = CACurrentMediaTime()

                // Convert buffer to Float32 array
                let samples = self.convertBufferToSamples(buffer)

                // Calculate RMS for pre-computed metrics
                let rms = self.calculateRMS(samples: samples)

                // Voice Activity Detection (VAD) - skip silent frames if enabled
                if config.vadEnabled && rms < 0.01 {
                    // Skip this frame - silence detected
                    print("[LoqaAudioBridge] VAD: Skipping silent frame (RMS=\(String(format: "%.4f", rms)))")
                    return
                }

                // Adaptive Processing - skip frames during low battery
                if config.adaptiveProcessing && self.isLowBatteryMode {
                    self.frameCounter += 1

                    // Notify user once when optimization is activated
                    if !self.batteryOptimizationNotified {
                        self.sendEvent("onStreamStatusChange", [
                            "status": "battery_optimized",
                            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                            "platform": "ios"
                        ])
                        self.batteryOptimizationNotified = true
                    }

                    // Skip every 2nd frame (reduce rate from ~8Hz to ~4Hz)
                    if self.frameCounter % 2 != 0 {
                        print("[LoqaAudioBridge] Adaptive: Skipping frame (low battery, frame=\(self.frameCounter))")
                        return
                    }
                }

                // Calculate timestamp (milliseconds since stream start)
                let timestamp = self.streamStartTime.map { streamStart in
                    Int64(Date().timeIntervalSince(streamStart) * 1000)
                } ?? 0

                // Emit audio samples event with pre-computed RMS
                self.sendEvent("onAudioSamples", [
                    "samples": samples,
                    "sampleRate": self.actualSampleRate,
                    "frameLength": samples.count,
                    "timestamp": timestamp,
                    "rms": rms
                ])

                // Check for buffer overflow (execution time > 90% of buffer duration)
                let endTime = CACurrentMediaTime()
                let executionTime = endTime - startTime
                let bufferDuration = Double(buffer.frameLength) / Double(self.actualSampleRate)

                if executionTime > bufferDuration * 0.9 {
                    // Warning: Approaching buffer overflow
                    print("[LoqaAudioBridge] Warning: Audio processing slow. Execution: \(String(format: "%.1f", executionTime * 1000)) ms, Buffer duration: \(String(format: "%.1f", bufferDuration * 1000)) ms")

                    // Emit overflow error event
                    self.sendEvent("onStreamError", [
                        "error": StreamErrorCode.bufferOverflow.rawValue,
                        "message": "Audio processing overloaded. Buffer processing took \(String(format: "%.0f", executionTime * 1000)) ms but buffer duration is \(String(format: "%.0f", bufferDuration * 1000)) ms. Try: (1) Increase buffer size, (2) Reduce processing load, (3) Restart streaming.",
                        "platform": "ios",
                        "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
                    ])
                }
            } // End autoreleasepool
        }
    }

    /// Calculate RMS (Root Mean Square) amplitude for audio samples
    /// - Parameter samples: Array of Float32 audio samples
    /// - Returns: RMS value in range [0.0, 1.0]
    private func calculateRMS(samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0.0 }

        let sumOfSquares = samples.reduce(0.0) { $0 + ($1 * $1) }
        return sqrt(sumOfSquares / Float(samples.count))
    }

    /// Check if device is in low battery mode
    /// - Returns: true if battery level is below 20%
    private func isLowBattery() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel

        // batteryLevel returns -1.0 if battery monitoring is not available
        if batteryLevel < 0 {
            return false
        }

        return batteryLevel < 0.2
    }

    /// Convert AVAudioPCMBuffer to Float32 array
    /// Uses buffer pooling to reduce allocations
    private func convertBufferToSamples(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else {
            return []
        }

        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        // Acquire buffer from pool
        var samples = bufferPool?.acquire() ?? [Float](repeating: 0.0, count: frameLength)

        // If mono, copy channel 0 directly
        if channelCount == 1 {
            for i in 0..<frameLength {
                samples[i] = channelData[0][i]
            }
        } else {
            // If stereo, convert to mono by averaging channels
            for frame in 0..<frameLength {
                var sum: Float = 0.0
                for channel in 0..<channelCount {
                    sum += channelData[channel][frame]
                }
                samples[frame] = sum / Float(channelCount)
            }
        }

        return samples
    }

    /// Handle AVAudioSession interruption notifications
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began (e.g., phone call, Siri)
            // Pause the audio engine
            audioEngine?.pause()

            // Emit status change event
            sendEvent("onStreamStatusChange", [
                "status": "paused",
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "platform": "ios"
            ])

        case .ended:
            // Interruption ended
            // Check if we should resume
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume) {
                // Resume streaming
                do {
                    try audioEngine?.start()

                    // Emit status change event
                    sendEvent("onStreamStatusChange", [
                        "status": "streaming",
                        "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                        "platform": "ios"
                    ])
                } catch {
                    // Failed to resume - emit error
                    sendEvent("onStreamError", [
                        "error": StreamErrorCode.engineStartFailed.rawValue,
                        "message": "Failed to resume after interruption: \(error.localizedDescription)",
                        "platform": "ios",
                        "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
                    ])

                    // Emit stopped status
                    sendEvent("onStreamStatusChange", [
                        "status": "stopped",
                        "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                        "platform": "ios"
                    ])
                }
            }

        @unknown default:
            break
        }
    }

    /// Clean up audio resources
    private func cleanup() {
        // Remove tap from input node
        inputNode?.removeTap(onBus: 0)

        // Stop audio engine
        audioEngine?.stop()

        // Deactivate audio session
        try? audioSession?.setActive(false)

        // Clear references
        audioEngine = nil
        inputNode = nil
        audioSession = nil
        streamStartTime = nil
        currentConfig = nil

        // Reset optimization state
        frameCounter = 0
        batteryOptimizationNotified = false
        isLowBatteryMode = false

        // Release buffer pool
        bufferPool = nil
    }

    /// Find the closest supported sample rate for iOS
    private func findClosestSupportedRate(requested: Int) -> Int {
        return supportedSampleRates.reduce(supportedSampleRates[0]) { closest, current in
            return abs(current - requested) < abs(closest - requested) ? current : closest
        }
    }

    /// Map NSError to StreamErrorCode
    private func mapErrorToCode(_ error: NSError) -> StreamErrorCode {
        // AVAudioSession error codes
        if error.domain == "com.apple.coreaudio.avfaudio" {
            switch error.code {
            case 560030580: // '!act' - Session activation failed
                return .sessionConfigFailed
            case 561015905: // '!cat' - Category not supported
                return .sessionConfigFailed
            default:
                return .deviceNotAvailable
            }
        }

        // Custom domain errors
        switch error.code {
        case 1001, 1002:
            return .sessionConfigFailed
        case 1003, 1004:
            return .deviceNotAvailable
        default:
            return .engineStartFailed
        }
    }
}
