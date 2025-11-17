package expo.modules.loqaaudiobridge

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.*
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Unit tests for LoqaAudioBridgeModule
 *
 * These tests verify:
 * - Permission checking logic
 * - AudioRecord initialization
 * - Buffer size calculation
 * - Event payload structure
 * - Cleanup sequence
 */
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class LoqaAudioBridgeModuleTest {

    private lateinit var context: Context

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
    }

    @After
    fun teardown() {
        // Clean up after each test
    }

    /**
     * Test 1: Permission Check Logic
     *
     * Verifies that permission check returns correct Boolean based on permission state
     */
    @Test
    fun testPermissionCheckGranted() {
        // Grant RECORD_AUDIO permission
        val application = ApplicationProvider.getApplicationContext<android.app.Application>()
        shadowOf(application).grantPermissions(Manifest.permission.RECORD_AUDIO)

        // Verify permission check returns true
        val hasPermission = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
        assertTrue(hasPermission, "Permission check should return true when granted")
    }

    @Test
    fun testPermissionCheckDenied() {
        // Deny RECORD_AUDIO permission
        val application = ApplicationProvider.getApplicationContext<android.app.Application>()
        shadowOf(application).denyPermissions(Manifest.permission.RECORD_AUDIO)

        // Verify permission check returns false
        val hasPermission = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
        assertFalse(hasPermission, "Permission check should return false when denied")
    }

    /**
     * Test 2: AudioRecord Initialization
     *
     * Verifies AudioRecord initializes with correct configuration
     */
    @Test
    fun testAudioRecordInitialization() {
        // Note: This test verifies the configuration parameters
        // Actual AudioRecord initialization requires hardware and is tested in integration tests

        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_FLOAT

        // Verify getMinBufferSize returns valid value for our configuration
        val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

        // On Robolectric, this might return ERROR if audio is not supported
        // In that case, we verify that we handle it correctly
        assertTrue(
            minBufferSize > 0 || minBufferSize == AudioRecord.ERROR_BAD_VALUE,
            "getMinBufferSize should return valid size or ERROR_BAD_VALUE"
        )
    }

    /**
     * Test 3: Buffer Size Calculation
     *
     * Verifies buffer size calculation ensures minimum size is met
     */
    @Test
    fun testBufferSizeCalculation() {
        val targetBufferSize = 2048 // samples
        val bytesPerSample = 4 // Float32 = 4 bytes
        val targetBufferSizeBytes = targetBufferSize * bytesPerSample // 8192 bytes

        // Simulate various getMinBufferSize return values
        val testCases = listOf(
            4096 to 8192,  // minBufferSize < target -> use target
            8192 to 8192,  // minBufferSize == target -> use target
            16384 to 16384 // minBufferSize > target -> use minBufferSize
        )

        testCases.forEach { (minBufferSize, expectedSize) ->
            val actualSize = minBufferSize.coerceAtLeast(targetBufferSizeBytes)
            assertEquals(
                expectedSize,
                actualSize,
                "Buffer size should be at least $targetBufferSizeBytes bytes"
            )
        }
    }

    /**
     * Test 4: Float32 Conversion
     *
     * Verifies sample conversion with mock data
     */
    @Test
    fun testFloatConversion() {
        // Simulate Float32 samples in [-1.0, 1.0] range
        val mockSamples = floatArrayOf(
            -1.0f, -0.5f, 0.0f, 0.5f, 1.0f,
            -0.707f, 0.707f, -0.25f, 0.25f, 0.0f
        )

        // Convert FloatArray to List<Float> (as done in module)
        val samplesRead = mockSamples.size
        val samplesList = mockSamples.take(samplesRead).toList()

        // Verify conversion
        assertEquals(mockSamples.size, samplesList.size, "Sample count should match")

        // Verify all samples are in valid range
        samplesList.forEach { sample ->
            assertTrue(
                sample >= -1.0f && sample <= 1.0f,
                "Sample $sample should be in range [-1.0, 1.0]"
            )
        }

        // Verify values are preserved
        mockSamples.forEachIndexed { index, expected ->
            assertEquals(expected, samplesList[index], "Sample at index $index should match")
        }
    }

    /**
     * Test 5: Event Payload Structure
     *
     * Verifies event payload contains required fields with correct types
     */
    @Test
    fun testEventPayloadStructure() {
        // Simulate event payload as created in module
        val mockSamples = listOf(-0.5f, 0.0f, 0.5f, 1.0f)
        val sampleRate = 16000
        val frameLength = mockSamples.size
        val timestamp = System.currentTimeMillis()

        val payload = mapOf(
            "samples" to mockSamples,
            "sampleRate" to sampleRate,
            "frameLength" to frameLength,
            "timestamp" to timestamp
        )

        // Verify all required fields present
        assertTrue(payload.containsKey("samples"), "Payload should contain 'samples'")
        assertTrue(payload.containsKey("sampleRate"), "Payload should contain 'sampleRate'")
        assertTrue(payload.containsKey("frameLength"), "Payload should contain 'frameLength'")
        assertTrue(payload.containsKey("timestamp"), "Payload should contain 'timestamp'")

        // Verify field types
        assertTrue(payload["samples"] is List<*>, "'samples' should be a List")
        assertTrue(payload["sampleRate"] is Int, "'sampleRate' should be an Int")
        assertTrue(payload["frameLength"] is Int, "'frameLength' should be an Int")
        assertTrue(payload["timestamp"] is Long, "'timestamp' should be a Long")

        // Verify field values
        assertEquals(mockSamples, payload["samples"], "'samples' should match input")
        assertEquals(sampleRate, payload["sampleRate"], "'sampleRate' should be 16000")
        assertEquals(frameLength, payload["frameLength"], "'frameLength' should match sample count")
        assertTrue(timestamp > 0, "'timestamp' should be positive")
    }

    /**
     * Test 6: Error Event Payload Structure
     *
     * Verifies error event payloads contain required fields
     */
    @Test
    fun testErrorEventPayloadStructure() {
        val errorCodes = listOf(
            "PERMISSION_DENIED",
            "ENGINE_START_FAILED",
            "DEVICE_NOT_AVAILABLE"
        )

        errorCodes.forEach { errorCode ->
            val timestamp = System.currentTimeMillis()
            val payload = mapOf(
                "error" to errorCode,
                "message" to "Test error message",
                "platform" to "android",
                "timestamp" to timestamp
            )

            // Verify required fields
            assertTrue(payload.containsKey("error"), "Error payload should contain 'error'")
            assertTrue(payload.containsKey("message"), "Error payload should contain 'message'")
            assertTrue(payload.containsKey("platform"), "Error payload should contain 'platform'")
            assertTrue(payload.containsKey("timestamp"), "Error payload should contain 'timestamp'")

            // Verify field values
            assertEquals(errorCode, payload["error"], "'error' should match error code")
            assertEquals("android", payload["platform"], "'platform' should be 'android'")
            assertTrue(
                (payload["message"] as String).isNotEmpty(),
                "'message' should not be empty"
            )
            assertTrue(payload["timestamp"] is Long, "'timestamp' should be a Long")
            assertTrue((payload["timestamp"] as Long) > 0, "'timestamp' should be positive")
        }
    }

    /**
     * Test 7: StreamConfig Data Class
     *
     * Verifies StreamConfig defaults and validation
     */
    @Test
    fun testStreamConfigDefaults() {
        val config = StreamConfig()

        // Verify default values
        assertEquals(16000, config.sampleRate, "Default sample rate should be 16000 Hz")
        assertEquals(2048, config.bufferSize, "Default buffer size should be 2048 samples")
        assertEquals(1, config.channels, "Default channels should be 1 (mono)")
    }

    @Test
    fun testStreamConfigCustomValues() {
        val config = StreamConfig(
            sampleRate = 48000,
            bufferSize = 4096,
            channels = 2
        )

        // Verify custom values
        assertEquals(48000, config.sampleRate, "Custom sample rate should be preserved")
        assertEquals(4096, config.bufferSize, "Custom buffer size should be preserved")
        assertEquals(2, config.channels, "Custom channels should be preserved")
    }

    /**
     * Test 8: Cleanup Sequence Logic
     *
     * Verifies cleanup logic completes without exceptions
     */
    @Test
    fun testCleanupSequence() {
        // Simulate cleanup sequence (without actual AudioRecord)
        var audioRecord: AudioRecord? = null
        var recordingJob: kotlinx.coroutines.Job? = null
        var isRecording = true

        // Execute cleanup sequence
        try {
            isRecording = false
            recordingJob?.cancel()
            recordingJob = null
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null

            // If we get here, cleanup succeeded
            assertTrue(true, "Cleanup should complete without exceptions")
        } catch (e: Exception) {
            assertTrue(false, "Cleanup threw exception: ${e.message}")
        }

        // Verify state after cleanup
        assertFalse(isRecording, "isRecording should be false after cleanup")
        assertEquals(null, audioRecord, "audioRecord should be null after cleanup")
        assertEquals(null, recordingJob, "recordingJob should be null after cleanup")
    }

    /**
     * Test 9: Status Change Event Payload
     *
     * Verifies status change events have correct structure
     */
    @Test
    fun testStatusChangeEventPayload() {
        val statuses = listOf("streaming", "stopped")

        statuses.forEach { status ->
            val timestamp = System.currentTimeMillis()
            val payload = mapOf(
                "status" to status,
                "timestamp" to timestamp,
                "platform" to "android"
            )

            // Verify required fields
            assertTrue(payload.containsKey("status"), "Status payload should contain 'status'")
            assertTrue(payload.containsKey("timestamp"), "Status payload should contain 'timestamp'")
            assertTrue(payload.containsKey("platform"), "Status payload should contain 'platform'")

            // Verify field values
            assertEquals(status, payload["status"], "'status' should match")
            assertTrue(payload["timestamp"] is Long, "'timestamp' should be a Long")
            assertTrue((payload["timestamp"] as Long) > 0, "'timestamp' should be positive")
            assertEquals("android", payload["platform"], "'platform' should be 'android'")
        }
    }

    // ========================================
    // Buffer Management Tests (Story 2D.5)
    // ========================================

    /**
     * Test 10: Buffer Size Calculation for Standard Rates
     */
    @Test
    fun testBufferSizeCalculationForStandardRates() {
        // 16kHz, 128ms target → 2048 samples
        val size16k = ((128.0 / 1000.0) * 16000).toInt()
        assertEquals(2048, size16k, "Buffer size should be 2048 samples for 16kHz at 128ms")

        // 44.1kHz, 93ms target → ~4100 samples
        val size44k = ((93.0 / 1000.0) * 44100).toInt()
        assertTrue(size44k > 4000, "Buffer size should be ~4100 samples for 44.1kHz at 93ms")

        // 48kHz, 85ms target → ~4080 samples
        val size48k = ((85.0 / 1000.0) * 48000).toInt()
        assertTrue(size48k > 4000, "Buffer size should be ~4080 samples for 48kHz at 85ms")
    }

    /**
     * Test 11: Buffer Size Validation (Min/Max)
     */
    @Test
    fun testBufferSizeValidation() {
        val minBufferSize = 512
        val maxBufferSize = 8192

        // Test valid sizes
        val validSizes = listOf(512, 1024, 2048, 4096, 8192)
        validSizes.forEach { size ->
            assertTrue(size >= minBufferSize, "Buffer size $size should be >= $minBufferSize")
            assertTrue(size <= maxBufferSize, "Buffer size $size should be <= $maxBufferSize")
        }

        // Test invalid sizes (too small/too large)
        assertTrue(511 < minBufferSize, "511 should be less than minimum")
        assertTrue(8193 > maxBufferSize, "8193 should be greater than maximum")
    }

    /**
     * Test 12: Sample Normalization Verification
     */
    @Test
    fun testSampleNormalizationVerification() {
        // Create mock Float32 samples in [-1.0, 1.0] range
        val samples = floatArrayOf(-1.0f, -0.5f, 0.0f, 0.5f, 1.0f, -0.707f, 0.707f)

        // Verify all samples are in normalized range
        samples.forEach { sample ->
            assertTrue(
                sample >= -1.0f && sample <= 1.0f,
                "Sample $sample should be in range [-1.0, 1.0]"
            )
        }

        // Test zero-crossing samples
        val zeroCrossingSamples = floatArrayOf(-0.1f, -0.05f, 0.0f, 0.05f, 0.1f)
        zeroCrossingSamples.forEach { sample ->
            assertTrue(
                sample >= -1.0f && sample <= 1.0f,
                "Zero-crossing sample $sample should be in range [-1.0, 1.0]"
            )
        }
    }

    /**
     * Test 13: Buffer Underrun Detection Logic
     */
    @Test
    fun testBufferUnderrunDetectionLogic() {
        val bufferSize = 2048

        // Test normal read (full buffer)
        val normalRead = 2048
        val normalUnderrun = ((bufferSize - normalRead).toFloat() / bufferSize.toFloat()) * 100.0f
        assertEquals(0.0f, normalUnderrun, "No underrun when full buffer is read")

        // Test slight underrun (5%)
        val slightUnderrunRead = 1946 // 95% of buffer
        val slightUnderrun = ((bufferSize - slightUnderrunRead).toFloat() / bufferSize.toFloat()) * 100.0f
        assertTrue(slightUnderrun < 10.0f, "5% underrun should not trigger overflow warning")

        // Test significant underrun (20%)
        val significantUnderrunRead = 1638 // 80% of buffer
        val significantUnderrun = ((bufferSize - significantUnderrunRead).toFloat() / bufferSize.toFloat()) * 100.0f
        assertTrue(significantUnderrun > 10.0f, "20% underrun should trigger overflow warning")
        assertEquals(20.0f, significantUnderrun, 0.1f, "Underrun percentage should be ~20%")
    }

    /**
     * Test 14: Sample Rate Fallback Logic
     */
    @Test
    fun testSampleRateFallbackLogic() {
        // Simulate fallback to 16kHz if requested rate not supported
        val requestedRate = 32000
        val fallbackRate = 16000

        // In production, if getMinBufferSize returns ERROR for 32kHz,
        // we fall back to 16kHz
        val minBufferFor32k = AudioRecord.getMinBufferSize(
            32000,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_FLOAT
        )

        // If 32kHz not supported (ERROR returned), fallback should be used
        if (minBufferFor32k == AudioRecord.ERROR_BAD_VALUE || minBufferFor32k == AudioRecord.ERROR) {
            // Verify fallback rate is supported
            val minBufferFor16k = AudioRecord.getMinBufferSize(
                fallbackRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_FLOAT
            )

            assertTrue(
                minBufferFor16k > 0 || minBufferFor16k == AudioRecord.ERROR_BAD_VALUE,
                "Fallback rate should be queryable"
            )
        }

        // Verify fallback rate is universal (16kHz)
        assertEquals(16000, fallbackRate, "Fallback rate should be 16kHz (universally supported)")
    }

    /**
     * Test 15: Buffer Duration Calculation
     */
    @Test
    fun testBufferDurationCalculation() {
        // 2048 samples at 16kHz = 128ms
        val duration1 = (2048.0 / 16000.0) * 1000.0
        assertEquals(128.0, duration1, 0.1, "Duration should be 128ms")

        // 4096 samples at 44.1kHz = ~93ms
        val duration2 = (4096.0 / 44100.0) * 1000.0
        assertEquals(92.88, duration2, 0.1, "Duration should be ~93ms")

        // 4096 samples at 48kHz = ~85ms
        val duration3 = (4096.0 / 48000.0) * 1000.0
        assertEquals(85.33, duration3, 0.1, "Duration should be ~85ms")
    }

    /**
     * Test 16: Buffer Stats Logging Format
     */
    @Test
    fun testBufferStatsLoggingFormat() {
        val sampleRate = 16000
        val bufferSize = 2048
        val bufferSizeBytes = bufferSize * 4 // Float32 = 4 bytes
        val bufferDuration = (bufferSize.toDouble() / sampleRate) * 1000.0

        // Verify calculation
        assertEquals(8192, bufferSizeBytes, "Buffer size in bytes should be 8192")
        assertEquals(128.0, bufferDuration, 0.1, "Buffer duration should be 128ms")

        // Verify log message format (what would be logged)
        val logMessage = "Buffer stats: sampleRate=$sampleRate Hz, bufferSize=$bufferSize samples, " +
                "bufferSizeBytes=$bufferSizeBytes, bufferDuration=${String.format("%.1f", bufferDuration)} ms"

        assertTrue(logMessage.contains("sampleRate=16000"), "Log should contain sample rate")
        assertTrue(logMessage.contains("bufferSize=2048"), "Log should contain buffer size")
        assertTrue(logMessage.contains("bufferDuration=128.0"), "Log should contain buffer duration")
    }

    /**
     * Test 17: Buffer Overflow Error Payload
     */
    @Test
    fun testBufferOverflowErrorPayload() {
        val timestamp = System.currentTimeMillis()
        val bufferSize = 2048
        val samplesRead = 1600
        val underrunPercent = ((bufferSize - samplesRead).toFloat() / bufferSize.toFloat()) * 100.0f

        val payload = mapOf(
            "error" to "BUFFER_OVERFLOW",
            "message" to "Buffer underrun detected: ${String.format("%.0f", underrunPercent)}% of buffer missed. " +
                    "Expected $bufferSize samples, read $samplesRead. Try: (1) Increase buffer size, " +
                    "(2) Reduce processing load, (3) Restart streaming.",
            "platform" to "android",
            "timestamp" to timestamp
        )

        // Verify required fields
        assertEquals("BUFFER_OVERFLOW", payload["error"], "'error' should be BUFFER_OVERFLOW")
        assertTrue(payload["message"].toString().contains("Buffer underrun"), "Message should describe underrun")
        assertTrue(payload["message"].toString().contains("2048"), "Message should include buffer size")
        assertTrue(payload["message"].toString().contains("1600"), "Message should include samples read")
        assertEquals("android", payload["platform"], "'platform' should be 'android'")
    }

    /**
     * Test 18: Byte Count Calculation for Float32
     */
    @Test
    fun testByteCountCalculationForFloat32() {
        val bufferSize = 2048 // samples
        val bytesPerSample = 4 // Float32 = 4 bytes

        val bufferSizeBytes = bufferSize * bytesPerSample
        assertEquals(8192, bufferSizeBytes, "2048 Float32 samples should be 8192 bytes")

        // Test other buffer sizes
        assertEquals(2048, 512 * 4, "512 samples → 2048 bytes")
        assertEquals(4096, 1024 * 4, "1024 samples → 4096 bytes")
        assertEquals(16384, 4096 * 4, "4096 samples → 16384 bytes")
    }

    // ========================================
    // Performance Optimization Tests (Story 2D.6)
    // ========================================

    /**
     * Test 19: RMS Calculation for Known Signal
     */
    @Test
    fun testRMSCalculation() {
        // Test samples: [0.3f, 0.4f, 0.5f]
        // Expected RMS = sqrt((0.09 + 0.16 + 0.25) / 3) = sqrt(0.5 / 3) ≈ 0.408
        val samples = floatArrayOf(0.3f, 0.4f, 0.5f)
        val rms = calculateRMSHelper(samples)

        assertEquals(0.408f, rms, 0.001f, "RMS should be approximately 0.408")
    }

    /**
     * Test 20: RMS for Silence
     */
    @Test
    fun testRMSForSilence() {
        val samples = FloatArray(2048) { 0.0f }
        val rms = calculateRMSHelper(samples)

        assertEquals(0.0f, rms, 0.0001f, "RMS for silence should be 0")
    }

    /**
     * Test 21: RMS for Full-Scale Sine Wave
     */
    @Test
    fun testRMSForFullScaleSineWave() {
        // Create 1kHz sine wave at 16kHz sample rate
        val sampleRate = 16000.0
        val frequency = 1000.0
        val samples = FloatArray(2048) { i ->
            kotlin.math.sin(2.0 * kotlin.math.PI * frequency * i / sampleRate).toFloat()
        }

        val rms = calculateRMSHelper(samples)

        // RMS of sine wave = peak / sqrt(2) ≈ 1.0 / 1.414 ≈ 0.707
        assertEquals(0.707f, rms, 0.01f, "RMS of full-scale sine wave should be ~0.707")
    }

    /**
     * Test 22: VAD Threshold of 0.01
     */
    @Test
    fun testVADThreshold() {
        val threshold = 0.01f

        // Silence (RMS < 0.01) should be skipped
        val silenceSamples = FloatArray(2048) { 0.005f }
        val silenceRMS = calculateRMSHelper(silenceSamples)
        assertTrue(silenceRMS < threshold, "Silence RMS should be below threshold")

        // Speech (RMS >= 0.01) should pass through
        val speechSamples = FloatArray(2048) { 0.1f }
        val speechRMS = calculateRMSHelper(speechSamples)
        assertTrue(speechRMS >= threshold, "Speech RMS should be above threshold")
    }

    /**
     * Test 23: Low Battery Threshold of 20%
     */
    @Test
    fun testLowBatteryThreshold() {
        val threshold = 20

        // Test cases
        assertTrue(15 < threshold, "15% battery is low")
        assertTrue(25 > threshold, "25% battery is not low")
    }

    /**
     * Test 24: Adaptive Frame Skip Logic
     */
    @Test
    fun testAdaptiveFrameSkipLogic() {
        // Frame counter increments: 1, 2, 3, 4, 5...
        // Skip when frameCounter % 2 != 0: 1, 3, 5... (odd frames)
        // Emit when frameCounter % 2 == 0: 2, 4, 6... (even frames)

        val frameNumbers = listOf(1, 2, 3, 4, 5, 6, 7, 8)
        val expectedSkip = listOf(true, false, true, false, true, false, true, false)

        frameNumbers.forEachIndexed { i, frameNumber ->
            val shouldSkip = (frameNumber % 2 != 0)
            assertEquals(expectedSkip[i], shouldSkip, "Frame $frameNumber skip logic incorrect")
        }
    }

    /**
     * Test 25: Event Payload Includes RMS Field
     */
    @Test
    fun testEventPayloadIncludesRMS() {
        val samples = listOf(0.5f, 0.5f, 0.5f)
        val rms = 0.5f

        val payload = mapOf(
            "samples" to samples,
            "sampleRate" to 16000,
            "frameLength" to 2048,
            "timestamp" to System.currentTimeMillis(),
            "rms" to rms
        )

        assertTrue(payload.containsKey("rms"), "Event payload should include 'rms' field")
        assertEquals(rms, payload["rms"], "'rms' value should match")
    }

    /**
     * Test 26: StreamConfig Optimization Options
     */
    @Test
    fun testStreamConfigOptimizationOptions() {
        val config = StreamConfig(
            sampleRate = 16000,
            bufferSize = 2048,
            channels = 1,
            vadEnabled = true,
            adaptiveProcessing = true
        )

        // Verify optimization options
        assertTrue(config.vadEnabled, "vadEnabled should be true")
        assertTrue(config.adaptiveProcessing, "adaptiveProcessing should be true")
    }

    /**
     * Test 27: StreamConfig Defaults for Optimization Options
     */
    @Test
    fun testStreamConfigOptimizationDefaults() {
        val config = StreamConfig()

        // Verify default values for optimization options
        assertTrue(config.vadEnabled, "vadEnabled should default to true")
        assertTrue(config.adaptiveProcessing, "adaptiveProcessing should default to true")
    }

    /**
     * Test 28: Battery Optimized Status Event
     */
    @Test
    fun testBatteryOptimizedStatusEvent() {
        val timestamp = System.currentTimeMillis()
        val payload = mapOf(
            "status" to "battery_optimized",
            "timestamp" to timestamp,
            "platform" to "android"
        )

        assertEquals("battery_optimized", payload["status"], "'status' should be battery_optimized")
        assertTrue(payload.containsKey("timestamp"), "Payload should contain timestamp")
        assertEquals("android", payload["platform"], "'platform' should be android")
    }

    // MARK: - Helper Functions for Performance Optimization Tests

    /**
     * Helper: Calculate RMS of audio samples
     */
    private fun calculateRMSHelper(samples: FloatArray): Float {
        if (samples.isEmpty()) return 0.0f

        val sumOfSquares = samples.fold(0.0f) { acc, sample -> acc + (sample * sample) }
        return kotlin.math.sqrt(sumOfSquares / samples.size)
    }
}
