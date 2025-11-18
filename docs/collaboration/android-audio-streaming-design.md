# Android Audio Streaming Implementation Design

**Platform:** Android API 23+ (Android 6.0 Marshmallow)
**Framework:** AudioRecord (android.media)
**Language:** Kotlin 1.9+
**Concurrency:** Kotlin Coroutines
**Module Type:** Expo Module
**Status:** Design Document
**Last Updated:** 2025-11-12

## Overview

This document specifies the Android implementation approach for VoicelineDSP v0.2.0 real-time audio streaming using AudioRecord and Kotlin Coroutines. The implementation captures audio from the device microphone, processes in Float32 format, and delivers samples to JavaScript via Expo EventEmitter.

### Key Technologies

- **AudioRecord:** Low-level audio capture API (direct access to microphone stream)
- **Kotlin Coroutines:** Background thread management (Dispatchers.IO for audio capture)
- **Float32 PCM:** Direct Float32 capture (ENCODING_PCM_FLOAT, API 23+)
- **Expo Module:** Event delivery to JavaScript (sendEvent on main thread)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                       Android Audio Stack                        │
└─────────────────────────────────────────────────────────────────┘

   Microphone
      │
      ▼
┌──────────────────┐
│  Permission      │  Request RECORD_AUDIO permission at runtime
│  Check/Request   │  Show rationale if previously denied
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  AudioRecord     │  Configure audio source, format, buffer size
│  Initialization  │  VOICE_RECOGNITION, CHANNEL_IN_MONO, ENCODING_PCM_FLOAT
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Start Recording │  AudioRecord.startRecording()
│  Background      │  Launch coroutine (Dispatchers.IO)
│  Coroutine       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Audio Buffer    │  AudioRecord.read() in loop (blocking)
│  Read Loop       │  Read Float32 samples into buffer
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Convert &       │  Convert FloatArray to List<Float>
│  Normalize       │  Already normalized to [-1.0, 1.0]
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Switch to       │  withContext(Dispatchers.Main)
│  Main Thread     │  Expo sendEvent requires main thread
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Expo Module     │  sendEvent("onAudioSample", payload)
│  EventEmitter    │  Deliver to JavaScript
└────────┬─────────┘
         │
         ▼
   JavaScript Layer
   (AudioSampleEvent)
```

---

## Implementation Components

### 1. Runtime Permission Request

Android requires runtime permission request for RECORD_AUDIO (API 23+).

```kotlin
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import expo.modules.kotlin.modules.Module

class VoicelineDSPModule : Module() {
    companion object {
        private const val PERMISSION_RECORD_AUDIO = Manifest.permission.RECORD_AUDIO
        private const val REQUEST_CODE_RECORD_AUDIO = 1001
    }

    /// Check if RECORD_AUDIO permission is granted
    private fun hasAudioPermission(): Boolean {
        val context = appContext.reactContext ?: return false
        return ContextCompat.checkSelfPermission(
            context,
            PERMISSION_RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    /// Request RECORD_AUDIO permission from user
    private fun requestAudioPermission() {
        val activity = appContext.currentActivity ?: run {
            sendEvent("onStreamError", mapOf(
                "error" to "PERMISSION_DENIED",
                "message" to "No activity available to request permission",
                "platform" to "android"
            ))
            return
        }

        // Check if we should show rationale (user previously denied)
        if (ActivityCompat.shouldShowRequestPermissionRationale(activity, PERMISSION_RECORD_AUDIO)) {
            // Show explanation to user before requesting again
            // This is a good place for trauma-informed messaging
            sendEvent("onStreamStatus", mapOf(
                "status" to "permission_rationale_needed",
                "message" to "Microphone access is needed for voice analysis features"
            ))
        }

        // Request permission
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(PERMISSION_RECORD_AUDIO),
            REQUEST_CODE_RECORD_AUDIO
        )
    }
}
```

**Permission Flow:**

1. **Check permission:** `hasAudioPermission()` before starting stream
2. **Request if not granted:** `requestAudioPermission()` shows system dialog
3. **Handle result:** `onRequestPermissionsResult` callback
4. **Retry or fail:** Emit error if permission denied

**Trauma-Informed Messaging:**

```kotlin
// Instead of: "Grant microphone permission or the app won't work"
// Use: "Microphone access helps us provide voice analysis features. You can enable this in Settings anytime."

private fun showPermissionRationale() {
    // Gentle, non-demanding explanation
    val message = """
        Voice features require microphone access to analyze your voice in real-time.
        Your audio is processed locally and never leaves your device.
        You can enable this permission in Settings anytime.
    """.trimIndent()

    // Show in UI (not implemented here, app responsibility)
}
```

---

### 2. AudioRecord Initialization

Configure AudioRecord with optimal settings for voice capture.

```kotlin
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder

class AudioStreamManager {
    private var audioRecord: AudioRecord? = null
    private var bufferSize: Int = 0

    /// Calculate minimum buffer size for AudioRecord
    private fun calculateBufferSize(sampleRate: Int, channelConfig: Int, audioFormat: Int): Int {
        val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

        if (minBufferSize == AudioRecord.ERROR || minBufferSize == AudioRecord.ERROR_BAD_VALUE) {
            throw StreamException.InvalidConfiguration(
                "Failed to calculate buffer size for sample rate $sampleRate"
            )
        }

        // Use 2x minimum buffer size for better reliability
        return minBufferSize * 2
    }

    /// Initialize AudioRecord instance
    fun initializeAudioRecord(config: StreamConfig) {
        val sampleRate = config.sampleRate
        val channelConfig = AudioFormat.CHANNEL_IN_MONO  // Mono input
        val audioFormat = AudioFormat.ENCODING_PCM_FLOAT  // Float32 format (API 23+)

        // Calculate buffer size
        bufferSize = calculateBufferSize(sampleRate, channelConfig, audioFormat)

        // Create AudioRecord instance
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,  // Optimized for voice
            sampleRate,
            channelConfig,
            audioFormat,
            bufferSize
        )

        // Verify initialization succeeded
        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            throw StreamException.InitializationFailed(
                "AudioRecord failed to initialize (state=${audioRecord?.state})"
            )
        }

        println("✅ AudioRecord initialized: sampleRate=$sampleRate, bufferSize=$bufferSize")
    }
}
```

**Configuration Details:**

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| **Audio Source** | `VOICE_RECOGNITION` | Optimized for voice capture (AGC, noise suppression) |
| **Channel Config** | `CHANNEL_IN_MONO` | Single channel (mono audio) |
| **Audio Format** | `ENCODING_PCM_FLOAT` | Float32 format, normalized to [-1.0, 1.0] |
| **Buffer Size** | 2× minimum | Better reliability, prevents buffer overruns |

**Alternative Audio Sources:**

- **`MIC`:** Raw microphone input (no processing)
- **`CAMCORDER`:** Optimized for video recording
- **`VOICE_COMMUNICATION`:** Optimized for VoIP (echo cancellation, high-pass filter)

**Format Notes:**

- **`ENCODING_PCM_FLOAT`:** Requires API 23+ (Android 6.0)
- **Fallback:** Use `ENCODING_PCM_16BIT` for older devices (convert to Float32)

---

### 3. Background Thread Model (Kotlin Coroutines)

Use Kotlin Coroutines for background audio capture.

```kotlin
import kotlinx.coroutines.*

class AudioStreamManager {
    private var recordingJob: Job? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    /// Start audio recording on background thread
    fun startRecording(config: StreamConfig, onSamplesReady: suspend (FloatArray, Int) -> Unit) {
        // Cancel any existing recording job
        recordingJob?.cancel()

        // Launch coroutine on IO dispatcher (optimized for blocking I/O)
        recordingJob = coroutineScope.launch(Dispatchers.IO) {
            val audioRecord = this@AudioStreamManager.audioRecord ?: run {
                println("❌ AudioRecord not initialized")
                return@launch
            }

            // Allocate buffer for reading samples
            val buffer = FloatArray(config.bufferSize)
            var startTime = System.currentTimeMillis()

            try {
                // Start recording
                audioRecord.startRecording()
                println("✅ AudioRecord started recording")

                // Read loop (blocking calls)
                while (isActive) {  // Check coroutine cancellation
                    val samplesRead = audioRecord.read(
                        buffer,
                        0,
                        config.bufferSize,
                        AudioRecord.READ_BLOCKING  // Block until buffer filled
                    )

                    if (samplesRead > 0) {
                        // Calculate timestamp (ms since start)
                        val timestamp = System.currentTimeMillis() - startTime

                        // Deliver samples (on current IO thread)
                        onSamplesReady(buffer.copyOf(samplesRead), timestamp.toInt())
                    } else {
                        // Error occurred
                        when (samplesRead) {
                            AudioRecord.ERROR_INVALID_OPERATION -> {
                                println("❌ AudioRecord error: INVALID_OPERATION")
                                break
                            }
                            AudioRecord.ERROR_BAD_VALUE -> {
                                println("❌ AudioRecord error: BAD_VALUE")
                                break
                            }
                            AudioRecord.ERROR_DEAD_OBJECT -> {
                                println("❌ AudioRecord error: DEAD_OBJECT")
                                break
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                println("❌ Recording error: ${e.message}")
            } finally {
                // Cleanup: stop recording
                audioRecord.stop()
                println("✅ AudioRecord stopped")
            }
        }
    }

    /// Stop recording and cleanup
    fun stopRecording() {
        recordingJob?.cancel()
        recordingJob = null

        audioRecord?.release()
        audioRecord = null

        println("✅ Recording stopped and resources released")
    }
}
```

**Coroutine Details:**

- **Dispatcher.IO:** Optimized for blocking I/O operations (audio read)
- **SupervisorJob:** Child coroutine failures don't cancel parent
- **isActive check:** Respects coroutine cancellation (clean shutdown)

**Read Modes:**

- **`READ_BLOCKING`:** Block until buffer filled (recommended, simplest)
- **`READ_NON_BLOCKING`:** Return immediately with available samples (requires handling partial reads)

---

### 4. Audio Buffer Reading and Conversion

Read Float32 samples from AudioRecord and prepare for JavaScript.

```kotlin
import android.media.AudioRecord

extension AudioStreamManager {
    /// Read audio samples from AudioRecord
    private fun readAudioSamples(audioRecord: AudioRecord, buffer: FloatArray): Int {
        return audioRecord.read(
            buffer,
            0,
            buffer.size,
            AudioRecord.READ_BLOCKING
        )
    }

    /// Convert FloatArray to List<Float> for JavaScript
    private fun convertToList(buffer: FloatArray, length: Int): List<Float> {
        // ENCODING_PCM_FLOAT is already normalized to [-1.0, 1.0]
        // No additional normalization needed
        return buffer.take(length)
    }
}
```

**Float32 Format:**

- **Range:** [-1.0, 1.0] (already normalized)
- **Size:** 4 bytes per sample
- **Conversion:** Direct copy to List<Float> (no transformation needed)

**Alternative: Int16 Format (API < 23)**

For older devices, use `ENCODING_PCM_16BIT` and convert:

```kotlin
private fun convertInt16ToFloat32(buffer: ShortArray, length: Int): List<Float> {
    return buffer.take(length).map { sample ->
        sample.toFloat() / 32768.0f  // Normalize Int16 [-32768, 32767] to Float32 [-1.0, 1.0]
    }
}
```

---

### 5. Event Emission on Main Thread

Emit audio samples to JavaScript on main thread (required by Expo).

```kotlin
import expo.modules.kotlin.modules.Module
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class VoicelineDSPModule : Module() {
    private var streamManager: AudioStreamManager? = null

    override fun definition() = ModuleDefinition {
        Name("VoicelineDSP")

        Events("onAudioSample", "onStreamStatus", "onStreamError")

        AsyncFunction("startAudioStream") { config: StreamConfig ->
            startStreaming(config)
        }

        AsyncFunction("stopAudioStream") {
            stopStreaming()
        }

        AsyncFunction("isStreaming") { ->
            streamManager?.isRecording() ?: false
        }
    }

    private suspend fun startStreaming(config: StreamConfig) {
        // Check permission first
        if (!hasAudioPermission()) {
            requestAudioPermission()
            throw StreamException.PermissionDenied("RECORD_AUDIO permission not granted")
        }

        val manager = AudioStreamManager()
        streamManager = manager

        try {
            // Initialize AudioRecord
            manager.initializeAudioRecord(config)

            // Start recording with sample callback
            manager.startRecording(config) { samples, timestamp ->
                // Currently on Dispatchers.IO (background thread)
                // Switch to Main dispatcher for event emission
                withContext(Dispatchers.Main) {
                    sendEvent("onAudioSample", mapOf(
                        "samples" to samples.toList(),
                        "sampleRate" to config.sampleRate,
                        "frameLength" to samples.size,
                        "timestamp" to timestamp
                    ))
                }
            }

            // Emit status event (on current thread, will be main)
            sendEvent("onStreamStatus", mapOf("status" to "streaming"))

        } catch (e: Exception) {
            streamManager = null
            sendEvent("onStreamError", mapOf(
                "error" to "ENGINE_START_FAILED",
                "message" to e.message,
                "platform" to "android"
            ))
            throw e
        }
    }

    private fun stopStreaming() {
        streamManager?.stopRecording()
        streamManager = null
        sendEvent("onStreamStatus", mapOf("status" to "stopped"))
    }
}
```

**Threading Model:**

1. **Audio read:** Dispatchers.IO (background thread, blocking read)
2. **Event emission:** Dispatchers.Main (main thread, required by Expo)
3. **Context switch:** `withContext(Dispatchers.Main)` for thread safety

**Event Payloads:**

- **onAudioSample:** `{ samples, sampleRate, frameLength, timestamp }`
- **onStreamStatus:** `{ status, timestamp? }`
- **onStreamError:** `{ error, message, platform, details? }`

---

### 6. Thread-Safe Cleanup

Cancel coroutine and release AudioRecord safely.

```kotlin
class AudioStreamManager {
    private var recordingJob: Job? = null
    private var audioRecord: AudioRecord? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    /// Stop recording and cleanup resources
    fun stopRecording() {
        // 1. Cancel coroutine (stops read loop)
        recordingJob?.cancel()
        recordingJob = null

        // 2. Stop AudioRecord (if still running)
        audioRecord?.let { record ->
            if (record.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                record.stop()
                println("✅ AudioRecord stopped")
            }

            // 3. Release AudioRecord resources
            record.release()
            println("✅ AudioRecord released")
        }

        audioRecord = null
    }

    /// Cleanup on module destruction
    fun cleanup() {
        stopRecording()
        coroutineScope.cancel()  // Cancel all coroutines
    }

    fun isRecording(): Boolean {
        return audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING
    }
}
```

**Cleanup Order:**

1. **Cancel coroutine** - Stops read loop gracefully
2. **Stop recording** - Halts audio capture
3. **Release resources** - Frees native audio resources

**Safe to call multiple times:** Subsequent calls are no-ops if already stopped.

---

## Complete Implementation Example

```kotlin
import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.core.content.ContextCompat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.*

// MARK: - Configuration Types

data class StreamConfig(
    val sampleRate: Int = 16000,
    val bufferSize: Int = 2048,
    val channels: Int = 1
)

sealed class StreamException(message: String) : Exception(message) {
    class PermissionDenied(message: String) : StreamException(message)
    class InvalidConfiguration(message: String) : StreamException(message)
    class InitializationFailed(message: String) : StreamException(message)
    class StartFailed(message: String) : StreamException(message)
}

// MARK: - Audio Stream Manager

class AudioStreamManager {
    private var audioRecord: AudioRecord? = null
    private var recordingJob: Job? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var bufferSizeInBytes: Int = 0

    fun initializeAudioRecord(config: StreamConfig) {
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_FLOAT

        val minBufferSize = AudioRecord.getMinBufferSize(config.sampleRate, channelConfig, audioFormat)
        if (minBufferSize <= 0) {
            throw StreamException.InvalidConfiguration("Invalid buffer size for sample rate ${config.sampleRate}")
        }

        bufferSizeInBytes = minBufferSize * 2

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            config.sampleRate,
            channelConfig,
            audioFormat,
            bufferSizeInBytes
        )

        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            throw StreamException.InitializationFailed("AudioRecord initialization failed")
        }
    }

    fun startRecording(config: StreamConfig, onSamplesReady: suspend (FloatArray, Int) -> Unit) {
        recordingJob?.cancel()

        recordingJob = coroutineScope.launch(Dispatchers.IO) {
            val record = audioRecord ?: return@launch
            val buffer = FloatArray(config.bufferSize)
            val startTime = System.currentTimeMillis()

            try {
                record.startRecording()

                while (isActive) {
                    val samplesRead = record.read(buffer, 0, config.bufferSize, AudioRecord.READ_BLOCKING)

                    if (samplesRead > 0) {
                        val timestamp = (System.currentTimeMillis() - startTime).toInt()
                        onSamplesReady(buffer.copyOf(samplesRead), timestamp)
                    } else if (samplesRead < 0) {
                        break  // Error occurred
                    }
                }
            } finally {
                record.stop()
            }
        }
    }

    fun stopRecording() {
        recordingJob?.cancel()
        recordingJob = null

        audioRecord?.let { record ->
            if (record.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                record.stop()
            }
            record.release()
        }
        audioRecord = null
    }

    fun isRecording(): Boolean {
        return audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING
    }

    fun cleanup() {
        stopRecording()
        coroutineScope.cancel()
    }
}

// MARK: - Expo Module

class VoicelineDSPModule : Module() {
    private var streamManager: AudioStreamManager? = null

    override fun definition() = ModuleDefinition {
        Name("VoicelineDSP")
        Events("onAudioSample", "onStreamStatus", "onStreamError")

        AsyncFunction("startAudioStream") { config: StreamConfig ->
            startStreaming(config)
        }

        AsyncFunction("stopAudioStream") {
            stopStreaming()
        }

        AsyncFunction("isStreaming") { ->
            streamManager?.isRecording() ?: false
        }

        OnDestroy {
            streamManager?.cleanup()
        }
    }

    private suspend fun startStreaming(config: StreamConfig) {
        val context = appContext.reactContext ?: throw StreamException.InitializationFailed("No context")

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            throw StreamException.PermissionDenied("RECORD_AUDIO permission not granted")
        }

        val manager = AudioStreamManager()
        streamManager = manager

        try {
            manager.initializeAudioRecord(config)

            manager.startRecording(config) { samples, timestamp ->
                withContext(Dispatchers.Main) {
                    sendEvent("onAudioSample", mapOf(
                        "samples" to samples.toList(),
                        "sampleRate" to config.sampleRate,
                        "frameLength" to samples.size,
                        "timestamp" to timestamp
                    ))
                }
            }

            sendEvent("onStreamStatus", mapOf("status" to "streaming"))

        } catch (e: Exception) {
            streamManager = null
            sendEvent("onStreamError", mapOf(
                "error" to "ENGINE_START_FAILED",
                "message" to e.message,
                "platform" to "android"
            ))
            throw e
        }
    }

    private fun stopStreaming() {
        streamManager?.stopRecording()
        streamManager = null
        sendEvent("onStreamStatus", mapOf("status" to "stopped"))
    }
}
```

---

## Performance Optimization

### 1. Buffer Size Tuning

Choose buffer size based on latency requirements:

| Sample Rate | Buffer Size | Latency | Min Buffer Size (typical) |
|-------------|-------------|---------|---------------------------|
| 16kHz | 2048 samples | 128ms | ~1024 samples |
| 44.1kHz | 4096 samples | 93ms | ~2048 samples |
| 48kHz | 4096 samples | 85ms | ~2304 samples |

**Recommendation:** Use 2× minimum buffer size for reliability

### 2. Use Efficient Data Structures

```kotlin
// Instead of:
val list = buffer.toList()  // Copies entire array

// Use:
val list = buffer.take(samplesRead)  // Only copies what was read
```

### 3. Minimize Main Thread Work

```kotlin
// Process samples on background thread before emitting
manager.startRecording(config) { samples, timestamp ->
    // Still on Dispatchers.IO - do heavy processing here
    val processedSamples = processSamples(samples)

    // Then switch to main thread only for event emission
    withContext(Dispatchers.Main) {
        sendEvent("onAudioSample", mapOf(...))
    }
}
```

---

## Error Scenarios

### Permission Denied

```kotlin
if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
    sendEvent("onStreamError", mapOf(
        "error" to "PERMISSION_DENIED",
        "message" to "Microphone permission not granted",
        "platform" to "android"
    ))
    throw StreamException.PermissionDenied("RECORD_AUDIO permission required")
}
```

### Device Not Available

```kotlin
val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
if (minBufferSize <= 0) {
    sendEvent("onStreamError", mapOf(
        "error" to "DEVICE_NOT_AVAILABLE",
        "message" to "Microphone not available (buffer size check failed)",
        "platform" to "android"
    ))
}
```

### Buffer Overflow Detection

```kotlin
val samplesRead = audioRecord.read(buffer, 0, bufferSize, AudioRecord.READ_BLOCKING)

if (samplesRead == AudioRecord.ERROR_INVALID_OPERATION) {
    sendEvent("onStreamError", mapOf(
        "error" to "BUFFER_OVERFLOW",
        "message" to "Audio frames are being dropped - consider increasing buffer size",
        "platform" to "android"
    ))
}
```

---

## Testing Recommendations

### Unit Tests

- Test buffer size calculation
- Test Float32 normalization (if using Int16 fallback)
- Test configuration validation
- Test error handling (null checks, state validation)

### Integration Tests (Instrumentation)

- Test AudioRecord initialization on real device
- Test recording lifecycle (start → read → stop)
- Test permission request flow
- Test coroutine cancellation (no leaks)

### Performance Tests

- Measure read loop timing (should be ~bufferDuration)
- Measure end-to-end latency (mic → JS event)
- Profile memory usage during long sessions
- Monitor battery impact (Android Profiler, Battery Historian)

---

## Next Steps

This design document serves as the blueprint for **Story 2D.3: Implement Android Native Streaming**.

Implementation checklist:
- [ ] Create Kotlin module in `modules/voiceline-dsp/android/`
- [ ] Implement AudioStreamManager class
- [ ] Implement VoicelineDSPModule with Expo bindings
- [ ] Add permission request handling
- [ ] Write unit tests for buffer handling
- [ ] Write instrumentation tests for AudioRecord lifecycle
- [ ] Profile performance and optimize
- [ ] Document any deviations from this design

---

## References

- [AudioRecord Documentation](https://developer.android.com/reference/android/media/AudioRecord)
- [AudioFormat Documentation](https://developer.android.com/reference/android/media/AudioFormat)
- [Runtime Permissions Guide](https://developer.android.com/training/permissions/requesting)
- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-guide.html)
- [Expo Modules API](https://docs.expo.dev/modules/module-api/)
