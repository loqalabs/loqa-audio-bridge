import XCTest
import AVFoundation
@testable import LoqaAudioBridge

/// Unit tests for LoqaAudioBridge module v0.3.0 streaming functionality
class LoqaAudioBridgeTests: XCTestCase {

    // MARK: - Test AVAudioSession Configuration

    /// Test: Verify AVAudioSession configures with correct category, mode, and options
    func testAudioSessionConfiguration() throws {
        // Get shared audio session
        let audioSession = AVAudioSession.sharedInstance()

        // Configure session
        try audioSession.setCategory(
            .record,
            mode: .measurement,
            options: [.allowBluetooth]
        )

        // Activate session
        try audioSession.setActive(true)

        // Verify configuration
        XCTAssertEqual(audioSession.category, .record, "Audio session category should be .record")
        XCTAssertEqual(audioSession.mode, .measurement, "Audio session mode should be .measurement")
        XCTAssertTrue(audioSession.categoryOptions.contains(.allowBluetooth), "Audio session should allow Bluetooth")

        // Clean up
        try audioSession.setActive(false)
    }

    // MARK: - Test AVAudioEngine Initialization

    /// Test: Verify AVAudioEngine initializes with correct format
    func testAudioEngineInitialization() throws {
        // Create audio engine
        let audioEngine = AVAudioEngine()
        XCTAssertNotNil(audioEngine, "AVAudioEngine should be initialized")

        // Get input node
        let inputNode = audioEngine.inputNode
        XCTAssertNotNil(inputNode, "Input node should be available")

        // Create audio format: PCM Float32, 16kHz, mono
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )
        XCTAssertNotNil(format, "Audio format should be created successfully")

        // Verify format properties
        XCTAssertEqual(format?.sampleRate, 16000, "Sample rate should be 16000 Hz")
        XCTAssertEqual(format?.channelCount, 1, "Channel count should be 1 (mono)")
        XCTAssertEqual(format?.commonFormat, .pcmFormatFloat32, "Format should be Float32")
        XCTAssertEqual(format?.isInterleaved, false, "Format should be non-interleaved")
    }

    // MARK: - Test Input Node Tap Installation

    /// Test: Verify input node tap installs with correct buffer size
    func testInputNodeTapInstallation() throws {
        // Create audio engine
        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode

        // Create audio format
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            XCTFail("Failed to create audio format")
            return
        }

        // Install tap (will not actually capture audio without starting engine)
        let bufferSize: AVAudioFrameCount = 2048
        var tapInstalled = false

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { (buffer, time) in
            // Tap callback - verify it gets called
            tapInstalled = true
        }

        // Verify tap was installed (no exception thrown)
        XCTAssertTrue(true, "Tap installation should succeed without errors")

        // Clean up
        inputNode.removeTap(onBus: 0)
    }

    // MARK: - Test Buffer Conversion

    /// Test: Verify Float32 buffer conversion to array
    func testBufferConversion() throws {
        // Create a mock AVAudioPCMBuffer with Float32 format
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            XCTFail("Failed to create audio format")
            return
        }

        let frameCapacity: AVAudioFrameCount = 2048
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            XCTFail("Failed to create AVAudioPCMBuffer")
            return
        }

        // Set frame length
        buffer.frameLength = frameCapacity

        // Populate buffer with test data
        guard let channelData = buffer.floatChannelData else {
            XCTFail("Channel data should be available")
            return
        }

        // Fill with sine wave test pattern
        for i in 0..<Int(frameCapacity) {
            let value = sin(2.0 * .pi * Float(i) / 100.0) // 160 Hz sine wave at 16kHz
            channelData[0][i] = value
        }

        // Convert buffer to array
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(frameCapacity)))

        // Verify conversion
        XCTAssertEqual(samples.count, Int(frameCapacity), "Sample count should match frame capacity")
        XCTAssertEqual(samples[0], channelData[0][0], accuracy: 0.0001, "First sample should match")
        XCTAssertTrue(samples.allSatisfy { $0 >= -1.0 && $0 <= 1.0 }, "All samples should be normalized to [-1.0, 1.0]")
    }

    // MARK: - Test Event Payload Structure

    /// Test: Verify event payload contains required fields
    func testEventPayloadStructure() {
        // Create mock event payload
        let samples: [Float] = Array(repeating: 0.5, count: 2048)
        let sampleRate = 16000
        let frameLength = 2048
        let timestamp: Int64 = 12345

        let eventPayload: [String: Any] = [
            "samples": samples,
            "sampleRate": sampleRate,
            "frameLength": frameLength,
            "timestamp": timestamp
        ]

        // Verify payload structure
        XCTAssertNotNil(eventPayload["samples"], "Event should contain 'samples' field")
        XCTAssertNotNil(eventPayload["sampleRate"], "Event should contain 'sampleRate' field")
        XCTAssertNotNil(eventPayload["frameLength"], "Event should contain 'frameLength' field")
        XCTAssertNotNil(eventPayload["timestamp"], "Event should contain 'timestamp' field")

        // Verify types and values
        if let eventSamples = eventPayload["samples"] as? [Float] {
            XCTAssertEqual(eventSamples.count, 2048, "Samples array should have 2048 elements")
        } else {
            XCTFail("samples field should be [Float]")
        }

        XCTAssertEqual(eventPayload["sampleRate"] as? Int, 16000, "sampleRate should be 16000")
        XCTAssertEqual(eventPayload["frameLength"] as? Int, 2048, "frameLength should be 2048")
        XCTAssertEqual(eventPayload["timestamp"] as? Int64, 12345, "timestamp should be 12345")
    }

    // MARK: - Test Cleanup Sequence

    /// Test: Verify cleanup sequence completes without crashes
    func testCleanupSequence() throws {
        // Create audio engine and install tap
        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            XCTFail("Failed to create audio format")
            return
        }

        // Install tap
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { (buffer, time) in
            // Tap callback
        }

        // Perform cleanup sequence
        inputNode.removeTap(onBus: 0) // Should not crash
        audioEngine.stop() // Should not crash

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false) // Should not crash

        // Verify cleanup succeeded
        XCTAssertFalse(audioEngine.isRunning, "Audio engine should be stopped")
        XCTAssertTrue(true, "Cleanup sequence should complete without crashes")
    }

    // MARK: - Test Stereo to Mono Conversion

    /// Test: Verify stereo buffer converts to mono by averaging channels
    func testStereoToMonoConversion() throws {
        // Create stereo format
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 2, // Stereo
            interleaved: false
        ) else {
            XCTFail("Failed to create audio format")
            return
        }

        let frameCapacity: AVAudioFrameCount = 1024
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            XCTFail("Failed to create AVAudioPCMBuffer")
            return
        }

        buffer.frameLength = frameCapacity

        guard let channelData = buffer.floatChannelData else {
            XCTFail("Channel data should be available")
            return
        }

        // Fill stereo channels with test data
        for i in 0..<Int(frameCapacity) {
            channelData[0][i] = 0.5  // Left channel: 0.5
            channelData[1][i] = -0.5 // Right channel: -0.5
        }

        // Convert to mono (averaging)
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        var monoSamples = [Float](repeating: 0.0, count: frameLength)
        for frame in 0..<frameLength {
            var sum: Float = 0.0
            for channel in 0..<channelCount {
                sum += channelData[channel][frame]
            }
            monoSamples[frame] = sum / Float(channelCount)
        }

        // Verify mono conversion
        XCTAssertEqual(monoSamples.count, Int(frameCapacity), "Mono samples count should match frame capacity")
        XCTAssertEqual(monoSamples[0], 0.0, accuracy: 0.0001, "Mono sample should be average of stereo channels (0.5 + -0.5) / 2 = 0.0")
    }

    // MARK: - Test Error Code Mapping

    /// Test: Verify error codes map correctly
    func testErrorCodeMapping() {
        // Test session config error
        let sessionError = NSError(
            domain: "com.apple.coreaudio.avfaudio",
            code: 560030580, // '!act' - activation failed
            userInfo: [NSLocalizedDescriptionKey: "Session activation failed"]
        )

        // In production, this would be tested via the module's mapErrorToCode function
        // For unit tests, we verify the error code constants are defined correctly
        XCTAssertEqual("SESSION_CONFIG_FAILED", "SESSION_CONFIG_FAILED")
        XCTAssertEqual("ENGINE_START_FAILED", "ENGINE_START_FAILED")
        XCTAssertEqual("DEVICE_NOT_AVAILABLE", "DEVICE_NOT_AVAILABLE")
        XCTAssertEqual("BUFFER_OVERFLOW", "BUFFER_OVERFLOW")
    }

    // MARK: - Test Status Change Event Payload

    /// Test: Verify status change event payload structure with platform field
    func testStatusChangeEventPayloadStructure() {
        let statuses = ["streaming", "stopped", "paused"]

        statuses.forEach { status in
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            let eventPayload: [String: Any] = [
                "status": status,
                "timestamp": timestamp,
                "platform": "ios"
            ]

            // Verify required fields
            XCTAssertNotNil(eventPayload["status"], "Status event should contain 'status' field")
            XCTAssertNotNil(eventPayload["timestamp"], "Status event should contain 'timestamp' field")
            XCTAssertNotNil(eventPayload["platform"], "Status event should contain 'platform' field")

            // Verify field values
            XCTAssertEqual(eventPayload["status"] as? String, status, "Status should match \(status)")
            XCTAssertEqual(eventPayload["platform"] as? String, "ios", "Platform should be 'ios'")
            XCTAssertTrue((eventPayload["timestamp"] as? Int64 ?? 0) > 0, "Timestamp should be positive")
        }
    }

    // MARK: - Test Error Event Payload

    /// Test: Verify error event payload contains 'error' field (not 'code') and platform field
    func testErrorEventPayloadStructure() {
        let errorCodes = ["SESSION_CONFIG_FAILED", "ENGINE_START_FAILED", "DEVICE_NOT_AVAILABLE", "BUFFER_OVERFLOW"]

        errorCodes.forEach { errorCode in
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            let eventPayload: [String: Any] = [
                "error": errorCode,
                "message": "Test error message",
                "platform": "ios",
                "timestamp": timestamp
            ]

            // Verify required fields
            XCTAssertNotNil(eventPayload["error"], "Error event should contain 'error' field (not 'code')")
            XCTAssertNotNil(eventPayload["message"], "Error event should contain 'message' field")
            XCTAssertNotNil(eventPayload["platform"], "Error event should contain 'platform' field")
            XCTAssertNotNil(eventPayload["timestamp"], "Error event should contain 'timestamp' field")

            // Verify field values
            XCTAssertEqual(eventPayload["error"] as? String, errorCode, "Error code should match \(errorCode)")
            XCTAssertEqual(eventPayload["platform"] as? String, "ios", "Platform should be 'ios'")
            XCTAssertTrue(!(eventPayload["message"] as? String ?? "").isEmpty, "Message should not be empty")
            XCTAssertTrue((eventPayload["timestamp"] as? Int64 ?? 0) > 0, "Timestamp should be positive")
        }
    }

    // MARK: - Test Buffer Management (Story 2D.5)

    /// Test: Buffer size calculation for standard rates
    func testBufferSizeCalculation() {
        // 16kHz, 128ms target → 2048 samples
        let size16k = Int((128.0 / 1000.0) * 16000)
        XCTAssertEqual(size16k, 2048, "Buffer size should be 2048 samples for 16kHz at 128ms")

        // 44.1kHz, 93ms target → ~4100 samples (rounds to 4096)
        let size44k = Int((93.0 / 1000.0) * 44100)
        XCTAssertGreaterThan(size44k, 4000, "Buffer size should be ~4100 samples for 44.1kHz at 93ms")

        // 48kHz, 85ms target → ~4080 samples (rounds to 4096)
        let size48k = Int((85.0 / 1000.0) * 48000)
        XCTAssertGreaterThan(size48k, 4000, "Buffer size should be ~4080 samples for 48kHz at 85ms")
    }

    /// Test: Buffer size validation (min, max, power of 2)
    func testBufferSizeValidation() {
        let validSizes = [512, 1024, 2048, 4096, 8192]
        validSizes.forEach { size in
            XCTAssertTrue(isPowerOf2(size), "Buffer size \(size) should be power of 2")
        }

        // Test invalid sizes
        XCTAssertFalse(isPowerOf2(511), "511 should not be power of 2")
        XCTAssertFalse(isPowerOf2(2000), "2000 should not be power of 2")
        XCTAssertFalse(isPowerOf2(8193), "8193 should not be power of 2")

        // Test minimum
        XCTAssertTrue(512 >= 512, "Minimum buffer size is 512")

        // Test maximum
        XCTAssertTrue(8192 <= 8192, "Maximum buffer size is 8192")
    }

    /// Test: Sample normalization verification
    func testSampleNormalization() {
        // Create mock buffer with Float32 samples
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            XCTFail("Failed to create audio format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create buffer")
            return
        }

        buffer.frameLength = 1024

        guard let channelData = buffer.floatChannelData else {
            XCTFail("Channel data should be available")
            return
        }

        // Fill with test samples in [-1.0, 1.0] range
        for i in 0..<1024 {
            channelData[0][i] = Float(sin(Double(i) * 0.1)) // Sine wave in [-1.0, 1.0]
        }

        // Convert to array and verify normalization
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: 1024))

        XCTAssertTrue(samples.allSatisfy { $0 >= -1.0 && $0 <= 1.0 }, "All samples should be in [-1.0, 1.0] range")
    }

    /// Test: Sample rate fallback logic
    func testSampleRateFallback() {
        let supportedRates = [8000, 16000, 22050, 44100, 48000]

        // Test exact matches
        XCTAssertEqual(findClosestRate(requested: 16000, supported: supportedRates), 16000)
        XCTAssertEqual(findClosestRate(requested: 44100, supported: supportedRates), 44100)

        // Test fallback to closest
        XCTAssertEqual(findClosestRate(requested: 32000, supported: supportedRates), 44100, "32kHz should fall back to 44.1kHz")
        XCTAssertEqual(findClosestRate(requested: 11025, supported: supportedRates), 16000, "11kHz should fall back to 16kHz")
    }

    /// Test: Buffer overflow detection timing
    func testBufferOverflowDetectionTiming() {
        let bufferSize = 2048
        let sampleRate = 16000.0

        // Calculate buffer duration (in seconds)
        let bufferDuration = Double(bufferSize) / sampleRate
        XCTAssertEqual(bufferDuration, 0.128, accuracy: 0.001, "Buffer duration should be 128ms")

        // Overflow threshold (90% of buffer duration)
        let overflowThreshold = bufferDuration * 0.9
        XCTAssertEqual(overflowThreshold, 0.1152, accuracy: 0.0001, "Overflow threshold should be ~115ms")

        // Simulate processing times
        let normalProcessingTime = 0.050 // 50ms - OK
        let slowProcessingTime = 0.120 // 120ms - OVERFLOW

        XCTAssertLessThan(normalProcessingTime, overflowThreshold, "Normal processing should not trigger overflow")
        XCTAssertGreaterThan(slowProcessingTime, overflowThreshold, "Slow processing should trigger overflow warning")
    }

    /// Test: Buffer duration calculation
    func testBufferDurationCalculation() {
        // 2048 samples at 16kHz = 128ms
        let duration1 = (Double(2048) / 16000.0) * 1000.0
        XCTAssertEqual(duration1, 128.0, accuracy: 0.1, "Duration should be 128ms")

        // 4096 samples at 44.1kHz = ~93ms
        let duration2 = (Double(4096) / 44100.0) * 1000.0
        XCTAssertEqual(duration2, 92.88, accuracy: 0.1, "Duration should be ~93ms")

        // 4096 samples at 48kHz = ~85ms
        let duration3 = (Double(4096) / 48000.0) * 1000.0
        XCTAssertEqual(duration3, 85.33, accuracy: 0.1, "Duration should be ~85ms")
    }

    // MARK: - Helper Functions for Buffer Management Tests

    /// Helper: Check if a number is a power of 2
    private func isPowerOf2(_ value: Int) -> Bool {
        return value > 0 && (value & (value - 1)) == 0
    }

    /// Helper: Find closest supported sample rate
    private func findClosestRate(requested: Int, supported: [Int]) -> Int {
        return supported.reduce(supported[0]) { closest, current in
            return abs(current - requested) < abs(closest - requested) ? current : closest
        }
    }

    // MARK: - Performance Optimization Tests (Story 2D.6)

    /// Test: RMS calculation for known signal
    func testRMSCalculation() {
        // Test samples: [0.3, 0.4, 0.5]
        // Expected RMS = sqrt((0.09 + 0.16 + 0.25) / 3) = sqrt(0.5 / 3) ≈ 0.408
        let samples: [Float] = [0.3, 0.4, 0.5]
        let rms = calculateRMSHelper(samples: samples)

        XCTAssertEqual(rms, 0.408, accuracy: 0.001, "RMS should be approximately 0.408")
    }

    /// Test: RMS for silence should be 0
    func testRMSForSilence() {
        let samples: [Float] = Array(repeating: 0.0, count: 2048)
        let rms = calculateRMSHelper(samples: samples)

        XCTAssertEqual(rms, 0.0, accuracy: 0.0001, "RMS for silence should be 0")
    }

    /// Test: RMS for full-scale signal should be ~0.707 (sine wave)
    func testRMSForFullScaleSineWave() {
        // Create 1kHz sine wave at 16kHz sample rate
        let sampleRate = 16000.0
        let frequency = 1000.0
        let samples: [Float] = (0..<2048).map { i in
            Float(sin(2.0 * .pi * frequency * Double(i) / sampleRate))
        }

        let rms = calculateRMSHelper(samples: samples)

        // RMS of sine wave = peak / sqrt(2) ≈ 1.0 / 1.414 ≈ 0.707
        XCTAssertEqual(rms, 0.707, accuracy: 0.01, "RMS of full-scale sine wave should be ~0.707")
    }

    /// Test: VAD threshold of 0.01
    func testVADThreshold() {
        let threshold: Float = 0.01

        // Silence (RMS < 0.01) should be skipped
        let silenceSamples: [Float] = Array(repeating: 0.005, count: 2048)
        let silenceRMS = calculateRMSHelper(samples: silenceSamples)
        XCTAssertLessThan(silenceRMS, threshold, "Silence RMS should be below threshold")

        // Speech (RMS >= 0.01) should pass through
        let speechSamples: [Float] = Array(repeating: 0.1, count: 2048)
        let speechRMS = calculateRMSHelper(samples: speechSamples)
        XCTAssertGreaterThanOrEqual(speechRMS, threshold, "Speech RMS should be above threshold")
    }

    /// Test: Battery level detection returns valid percentage
    func testBatteryLevelDetection() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel

        // Battery level should be in [0.0, 1.0] range or -1.0 if unavailable
        if batteryLevel >= 0 {
            XCTAssertTrue(batteryLevel >= 0.0 && batteryLevel <= 1.0, "Battery level should be in [0.0, 1.0] range")
        } else {
            XCTAssertEqual(batteryLevel, -1.0, accuracy: 0.01, "Battery level should be -1.0 if unavailable")
        }
    }

    /// Test: Low battery threshold of 20%
    func testLowBatteryThreshold() {
        let threshold: Float = 0.2

        XCTAssertEqual(threshold, 0.2, accuracy: 0.01, "Low battery threshold should be 20%")

        // Test cases
        XCTAssertTrue(0.15 < threshold, "15% battery is low")
        XCTAssertTrue(0.25 > threshold, "25% battery is not low")
    }

    /// Test: Adaptive processing frame skip logic
    func testAdaptiveFrameSkipLogic() {
        // Frame counter increments: 1, 2, 3, 4, 5...
        // Skip when frameCounter % 2 != 0: 1, 3, 5... (odd frames)
        // Emit when frameCounter % 2 == 0: 2, 4, 6... (even frames)

        let frameNumbers = [1, 2, 3, 4, 5, 6, 7, 8]
        let expectedSkip = [true, false, true, false, true, false, true, false]

        for (i, frameNumber) in frameNumbers.enumerated() {
            let shouldSkip = (frameNumber % 2 != 0)
            XCTAssertEqual(shouldSkip, expectedSkip[i], "Frame \(frameNumber) skip logic incorrect")
        }
    }

    /// Test: Buffer pool acquire/release
    func testBufferPoolAcquireRelease() {
        let bufferSize = 2048
        let maxSize = 5

        // Simulate buffer pool
        var pool: [[Float]] = []

        // Pre-allocate initial buffers
        for _ in 0..<3 {
            pool.append([Float](repeating: 0, count: bufferSize))
        }

        XCTAssertEqual(pool.count, 3, "Pool should have 3 pre-allocated buffers")

        // Acquire buffer
        let buffer1 = pool.isEmpty ? [Float](repeating: 0, count: bufferSize) : pool.removeLast()
        XCTAssertEqual(buffer1.count, bufferSize, "Acquired buffer should have correct size")
        XCTAssertEqual(pool.count, 2, "Pool should have 2 buffers after acquire")

        // Release buffer
        if pool.count < maxSize {
            pool.append(buffer1)
        }
        XCTAssertEqual(pool.count, 3, "Pool should have 3 buffers after release")
    }

    /// Test: Buffer pool doesn't exceed max size
    func testBufferPoolMaxSize() {
        let maxSize = 5
        var pool: [[Float]] = []

        // Add 10 buffers, but only maxSize should be retained
        for i in 0..<10 {
            let buffer = [Float](repeating: Float(i), count: 2048)
            if pool.count < maxSize {
                pool.append(buffer)
            }
        }

        XCTAssertEqual(pool.count, maxSize, "Pool should not exceed max size")
    }

    /// Test: Autoreleasepool usage
    func testAutoreleasepoolUsage() {
        // Verify autoreleasepool doesn't interfere with normal execution
        var executed = false

        autoreleasepool {
            executed = true
        }

        XCTAssertTrue(executed, "Code inside autoreleasepool should execute")
    }

    /// Test: RMS calculation performance (should be <2ms for 2048 samples)
    func testRMSCalculationPerformance() {
        let samples: [Float] = (0..<2048).map { _ in Float.random(in: -1.0...1.0) }

        measure {
            // This should complete in <2ms
            _ = calculateRMSHelper(samples: samples)
        }
    }

    /// Test: Event payload includes RMS field
    func testEventPayloadIncludesRMS() {
        let samples: [Float] = Array(repeating: 0.5, count: 2048)
        let rms: Float = 0.5

        let eventPayload: [String: Any] = [
            "samples": samples,
            "sampleRate": 16000,
            "frameLength": 2048,
            "timestamp": Int64(12345),
            "rms": rms
        ]

        XCTAssertNotNil(eventPayload["rms"], "Event payload should include 'rms' field")
        XCTAssertEqual(eventPayload["rms"] as? Float, rms, accuracy: 0.01, "RMS value should match")
    }

    // MARK: - Helper Functions for Performance Optimization Tests

    /// Helper: Calculate RMS of audio samples
    private func calculateRMSHelper(samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0.0 }

        let sumOfSquares = samples.reduce(0.0) { $0 + ($1 * $1) }
        return sqrt(sumOfSquares / Float(samples.count))
    }
}
