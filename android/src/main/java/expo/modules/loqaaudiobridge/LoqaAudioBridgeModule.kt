package expo.modules.loqaaudiobridge

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.BatteryManager
import androidx.core.content.ContextCompat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import kotlinx.coroutines.*

/**
 * StreamConfig - Configuration for audio streaming
 *
 * @property sampleRate Sample rate in Hz (default: 16000)
 * @property bufferSize Number of samples per buffer (default: 2048)
 * @property channels Number of audio channels (default: 1 for mono)
 * @property vadEnabled Enable Voice Activity Detection to skip silent frames (default: true)
 * @property adaptiveProcessing Enable adaptive frame rate during low battery (default: true)
 */
data class StreamConfig(
    @Field val sampleRate: Int = 16000,
    @Field val bufferSize: Int = 2048,
    @Field val channels: Int = 1,
    @Field val vadEnabled: Boolean = true,
    @Field val adaptiveProcessing: Boolean = true
) : Record

/**
 * LoqaAudioBridgeModule - Expo module for real-time audio streaming and DSP analysis
 *
 * This module provides:
 * - Real-time audio capture using AudioRecord
 * - Event-based audio sample streaming to JavaScript
 * - Voice DSP analysis functions (FFT, pitch, etc.)
 *
 * Audio Configuration:
 * - Source: VOICE_RECOGNITION (optimized for speech)
 * - Format: PCM Float32, mono, 16kHz
 * - Buffer: 2048 samples (128ms at 16kHz)
 * - Threading: Dispatchers.IO for audio capture, Dispatchers.Main for events
 */
class LoqaAudioBridgeModule : Module() {
    // Audio recording state
    private var audioRecord: AudioRecord? = null
    private var recordingJob: Job? = null
    private var isRecording = false

    // Actual sample rate used (may differ from requested if fallback occurred)
    private var actualSampleRate: Int = 16000

    // Cached battery level status
    private var isLowBatteryMode: Boolean = false

    // Frame counter for adaptive processing
    private var frameCounter: Int = 0

    // Battery optimization notification flag
    private var batteryOptimizationNotified: Boolean = false

    override fun definition() = ModuleDefinition {
        Name("LoqaAudioBridge")

        // Event definitions
        Events("onAudioSamples", "onStreamError", "onStreamStatusChange")

        /**
         * Start audio streaming
         *
         * Initializes AudioRecord, starts background recording loop, and begins
         * emitting onAudioSamples events with captured audio data.
         *
         * @param config StreamConfig with sampleRate, bufferSize, channels
         * @return Boolean - true if started successfully, false if failed
         */
        AsyncFunction("startAudioStream") { config: StreamConfig ->
            startAudioStreamInternal(config)
        }

        /**
         * Stop audio streaming
         *
         * Cancels recording coroutine, stops AudioRecord, releases resources.
         *
         * @return Boolean - true if stopped successfully
         */
        Function("stopAudioStream") {
            stopAudioStreamInternal()
        }

        /**
         * Check if currently streaming
         *
         * @return Boolean - true if audio stream is active
         */
        Function("isStreaming") {
            isRecording
        }
    }

    /**
     * Check if RECORD_AUDIO permission is granted
     */
    private fun checkRecordPermission(): Boolean {
        val context = appContext.reactContext ?: return false
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Initialize AudioRecord with specified configuration
     *
     * Includes sample rate fallback logic: if requested rate is not supported,
     * falls back to 16kHz (universally supported).
     *
     * @param config StreamConfig with audio parameters
     * @return Result<AudioRecord, String> - AudioRecord instance or error message
     */
    private fun initializeAudioRecord(config: StreamConfig): Result<AudioRecord> {
        try {
            var sampleRateToUse = config.sampleRate
            var minBufferSize = AudioRecord.getMinBufferSize(
                sampleRateToUse,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_FLOAT
            )

            // Check if requested rate is supported
            if (minBufferSize == AudioRecord.ERROR_BAD_VALUE || minBufferSize == AudioRecord.ERROR) {
                // Try fallback to 16kHz (universally supported)
                android.util.Log.w("LoqaAudioBridge", "Requested sample rate $sampleRateToUse Hz not supported. Attempting fallback to 16000 Hz.")
                sampleRateToUse = 16000
                minBufferSize = AudioRecord.getMinBufferSize(
                    sampleRateToUse,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_FLOAT
                )

                // If 16kHz also fails, give up
                if (minBufferSize == AudioRecord.ERROR_BAD_VALUE || minBufferSize == AudioRecord.ERROR) {
                    return Result.failure(
                        Exception("AudioRecord configuration not supported even with 16kHz fallback")
                    )
                }
            }

            // Store actual sample rate used
            actualSampleRate = sampleRateToUse

            // Ensure buffer size is at least our target size (Float32 = 4 bytes per sample)
            val bufferSizeBytes = minBufferSize.coerceAtLeast(config.bufferSize * 4)

            // Log buffer stats
            val bufferDuration = (config.bufferSize.toDouble() / actualSampleRate) * 1000.0
            android.util.Log.i("LoqaAudioBridge", "Buffer stats: sampleRate=$actualSampleRate Hz, bufferSize=${config.bufferSize} samples, bufferSizeBytes=$bufferSizeBytes, bufferDuration=${String.format("%.1f", bufferDuration)} ms, minBufferSize=$minBufferSize bytes")

            // Create AudioRecord instance
            val audioRecord = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                actualSampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_FLOAT,
                bufferSizeBytes
            )

            // Verify initialization succeeded
            if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
                audioRecord.release()
                return Result.failure(
                    Exception("AudioRecord failed to initialize (state=${audioRecord.state})")
                )
            }

            return Result.success(audioRecord)
        } catch (e: Exception) {
            return Result.failure(e)
        }
    }

    /**
     * Calculate RMS (Root Mean Square) amplitude for audio samples
     *
     * @param samples FloatArray of audio samples
     * @return RMS value in range [0.0, 1.0]
     */
    private fun calculateRMS(samples: FloatArray): Float {
        if (samples.isEmpty()) return 0.0f

        val sumOfSquares = samples.fold(0.0f) { acc, sample -> acc + (sample * sample) }
        return kotlin.math.sqrt(sumOfSquares / samples.size)
    }

    /**
     * Get battery level from system
     *
     * @return Battery level percentage (0-100), or -1 if unavailable
     */
    private fun getBatteryLevel(): Int {
        val context = appContext.reactContext ?: return -1
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        return batteryManager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
    }

    /**
     * Check if device is in low battery mode
     *
     * @return true if battery level is below 20%
     */
    private fun isLowBattery(): Boolean {
        val batteryLevel = getBatteryLevel()
        if (batteryLevel < 0) {
            return false
        }
        return batteryLevel < 20
    }

    /**
     * Background recording loop
     *
     * Runs on Dispatchers.IO, continuously reads audio samples from AudioRecord,
     * switches to Main thread to emit events.
     *
     * @param config StreamConfig with buffer configuration
     */
    private suspend fun startRecordingLoop(config: StreamConfig) {
        withContext(Dispatchers.IO) {
            try {
                // Allocate buffer for audio samples
                val buffer = FloatArray(config.bufferSize)

                // Start recording
                audioRecord?.startRecording()

                // Recording loop - continues while coroutine is active and recording flag is set
                while (isActive && isRecording) {
                    // Read audio samples (blocking call)
                    val samplesRead = audioRecord?.read(
                        buffer,
                        0,
                        buffer.size,
                        AudioRecord.READ_BLOCKING
                    ) ?: -1

                    // Check for read errors
                    if (samplesRead < 0) {
                        // Error reading samples
                        withContext(Dispatchers.Main) {
                            sendEvent("onStreamError", mapOf(
                                "error" to "DEVICE_NOT_AVAILABLE",
                                "message" to "AudioRecord read failed with error code: $samplesRead",
                                "platform" to "android",
                                "timestamp" to System.currentTimeMillis()
                            ))
                        }
                        break
                    }

                    // Check for buffer underrun (overflow detection)
                    if (samplesRead < buffer.size) {
                        val underrunPercent = ((buffer.size - samplesRead).toFloat() / buffer.size.toFloat()) * 100.0f

                        // Only warn if underrun is significant (>10%)
                        if (underrunPercent > 10.0f) {
                            android.util.Log.w("LoqaAudioBridge", "Buffer underrun: ${String.format("%.1f", underrunPercent)}% (expected ${buffer.size} samples, read $samplesRead)")

                            // Emit buffer overflow error
                            withContext(Dispatchers.Main) {
                                sendEvent("onStreamError", mapOf(
                                    "error" to "BUFFER_OVERFLOW",
                                    "message" to "Buffer underrun detected: ${String.format("%.0f", underrunPercent)}% of buffer missed. Expected ${buffer.size} samples, read $samplesRead. Try: (1) Increase buffer size, (2) Reduce processing load, (3) Restart streaming.",
                                    "platform" to "android",
                                    "timestamp" to System.currentTimeMillis()
                                ))
                            }
                        }
                    }

                    if (samplesRead > 0) {
                        // Calculate RMS for pre-computed metrics
                        val rms = calculateRMS(buffer.sliceArray(0 until samplesRead))

                        // Voice Activity Detection (VAD) - skip silent frames if enabled
                        if (config.vadEnabled && rms < 0.01f) {
                            // Skip this frame - silence detected
                            android.util.Log.d("LoqaAudioBridge", "VAD: Skipping silent frame (RMS=${String.format("%.4f", rms)})")
                            continue
                        }

                        // Adaptive Processing - skip frames during low battery
                        if (config.adaptiveProcessing && isLowBatteryMode) {
                            frameCounter++

                            // Notify user once when optimization is activated
                            if (!batteryOptimizationNotified) {
                                withContext(Dispatchers.Main) {
                                    sendEvent("onStreamStatusChange", mapOf(
                                        "status" to "battery_optimized",
                                        "timestamp" to System.currentTimeMillis(),
                                        "platform" to "android"
                                    ))
                                }
                                batteryOptimizationNotified = true
                            }

                            // Skip every 2nd frame (reduce rate from ~8Hz to ~4Hz)
                            if (frameCounter % 2 != 0) {
                                android.util.Log.d("LoqaAudioBridge", "Adaptive: Skipping frame (low battery, frame=$frameCounter)")
                                continue
                            }
                        }

                        // Prepare event payload (minimize allocations by batching metadata)
                        val timestamp = System.currentTimeMillis()
                        val samples = buffer.take(samplesRead).toList()

                        // Switch to Main thread for event emission
                        withContext(Dispatchers.Main) {
                            // Batch all metadata into single map allocation
                            sendEvent("onAudioSamples", mapOf(
                                "samples" to samples,
                                "sampleRate" to actualSampleRate,
                                "frameLength" to samplesRead,
                                "timestamp" to timestamp,
                                "rms" to rms
                            ))
                        }
                    }
                }
            } catch (e: CancellationException) {
                // Normal cancellation - don't report as error
                throw e
            } catch (e: Exception) {
                // Unexpected error during recording
                withContext(Dispatchers.Main) {
                    sendEvent("onStreamError", mapOf(
                        "error" to "DEVICE_NOT_AVAILABLE",
                        "message" to "Recording error: ${e.message}",
                        "platform" to "android",
                        "timestamp" to System.currentTimeMillis()
                    ))
                }
            }
        }
    }

    /**
     * Internal implementation of startAudioStream
     */
    private suspend fun startAudioStreamInternal(config: StreamConfig): Boolean {
        // Check if already recording
        if (isRecording) {
            sendEvent("onStreamError", mapOf(
                "error" to "ENGINE_START_FAILED",
                "message" to "Audio stream is already active",
                "platform" to "android",
                "timestamp" to System.currentTimeMillis()
            ))
            return false
        }

        // Check permission
        if (!checkRecordPermission()) {
            sendEvent("onStreamError", mapOf(
                "error" to "PERMISSION_DENIED",
                "message" to "Microphone permission required for voice analysis. Your voice is processed on-device and never saved or uploaded.",
                "platform" to "android",
                "timestamp" to System.currentTimeMillis()
            ))
            return false
        }

        // Initialize AudioRecord
        val result = initializeAudioRecord(config)
        if (result.isFailure) {
            sendEvent("onStreamError", mapOf(
                "error" to "ENGINE_START_FAILED",
                "message" to "Failed to initialize AudioRecord: ${result.exceptionOrNull()?.message}",
                "platform" to "android",
                "timestamp" to System.currentTimeMillis()
            ))
            return false
        }

        audioRecord = result.getOrNull()

        // Check battery level and cache the result
        isLowBatteryMode = isLowBattery()

        // Start recording loop in background
        recordingJob = CoroutineScope(Dispatchers.IO).launch {
            startRecordingLoop(config)
        }

        isRecording = true

        // Emit status change event
        sendEvent("onStreamStatusChange", mapOf(
            "status" to "streaming",
            "timestamp" to System.currentTimeMillis(),
            "platform" to "android"
        ))

        return true
    }

    /**
     * Internal implementation of stopAudioStream
     */
    private fun stopAudioStreamInternal(): Boolean {
        if (!isRecording) {
            return false
        }

        // Set recording flag to false (will stop loop)
        isRecording = false

        // Cancel coroutine
        recordingJob?.cancel()
        recordingJob = null

        // Stop and release AudioRecord
        try {
            audioRecord?.stop()
        } catch (e: Exception) {
            // Ignore stop errors
        }

        try {
            audioRecord?.release()
        } catch (e: Exception) {
            // Ignore release errors
        }

        audioRecord = null

        // Reset optimization state
        frameCounter = 0
        batteryOptimizationNotified = false
        isLowBatteryMode = false

        // Emit status change event
        sendEvent("onStreamStatusChange", mapOf(
            "status" to "stopped",
            "timestamp" to System.currentTimeMillis(),
            "platform" to "android"
        ))

        return true
    }
}
