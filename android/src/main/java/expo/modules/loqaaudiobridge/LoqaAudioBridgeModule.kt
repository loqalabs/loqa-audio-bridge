package expo.modules.loqaaudiobridge

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.core.content.ContextCompat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import kotlinx.coroutines.*
import java.net.URL

/**
 * StreamConfig - Configuration for audio streaming (from v0.2.0)
 */
data class StreamConfig(
    @Field val sampleRate: Int = 16000,
    @Field val bufferSize: Int = 2048,
    @Field val channels: Int = 1,
    @Field val vadEnabled: Boolean = true,
    @Field val adaptiveProcessing: Boolean = true
) : Record

class LoqaAudioBridgeModule : Module() {
  // Audio recording state (v0.2.0)
  private var audioRecord: AudioRecord? = null
  private var recordingJob: Job? = null
  private var isRecording = false

  // Actual sample rate used (may differ from requested if fallback occurred)
  private var actualSampleRate: Int = 16000
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  override fun definition() = ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('LoqaAudioBridgeModule')` in JavaScript.
    Name("LoqaAudioBridgeModule")

    // Defines constant property on the module.
    Constant("PI") {
      Math.PI
    }

    // Defines event names that the module can send to JavaScript.
    Events("onChange", "onAudioSamples", "onStreamError", "onStreamStatusChange")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("hello") {
      "Hello world! 👋"
    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("setValueAsync") { value: String ->
      // Send an event to JavaScript.
      sendEvent("onChange", mapOf(
        "value" to value
      ))
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of
    // the view definition: Prop, Events.
    View(LoqaAudioBridgeModuleView::class) {
      // Defines a setter for the `url` prop.
      Prop("url") { view: LoqaAudioBridgeModuleView, url: URL ->
        view.webView.loadUrl(url.toString())
      }
      // Defines an event that the view can send to JavaScript.
      Events("onLoad")
    }
  }

  // MARK: - Private Helper Functions (v0.2.0 audio capture)

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

      actualSampleRate = sampleRateToUse

      // Create AudioRecord instance
      val record = AudioRecord(
        MediaRecorder.AudioSource.VOICE_RECOGNITION,
        sampleRateToUse,
        AudioFormat.CHANNEL_IN_MONO,
        AudioFormat.ENCODING_PCM_FLOAT,
        minBufferSize * 4 // Float32 = 4 bytes per sample
      )

      return Result.success(record)

    } catch (e: Exception) {
      return Result.failure(e)
    }
  }
}
