import AVFoundation
import ExpoModulesCore
import UIKit

/// Configuration for audio streaming session (from v0.2.0)
struct StreamConfig: Record {
    @Field var sampleRate: Int = 16000
    @Field var bufferSize: Int = 2048
    @Field var channels: Int = 1
    @Field var vadEnabled: Bool = true
    @Field var adaptiveProcessing: Bool = true
}

public class LoqaAudioBridgeModule: Module {
  // MARK: - Properties (v0.2.0 audio capture)

  /// Audio engine for capturing microphone input
  private var audioEngine: AVAudioEngine?

  /// Input node from the audio engine
  private var inputNode: AVAudioInputNode?

  /// Audio session for managing audio configuration
  private var audioSession: AVAudioSession?

  /// Supported sample rates for iOS (AVAudioEngine)
  private let supportedSampleRates = [8000, 16000, 22050, 44100, 48000]
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('LoqaAudioBridgeModule')` in JavaScript.
    Name("LoqaAudioBridgeModule")

    // Defines constant property on the module.
    Constant("PI") {
      Double.pi
    }

    // Defines event names that the module can send to JavaScript.
    Events("onChange", "onAudioSamples", "onStreamError", "onStreamStatusChange")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("hello") {
      return "Hello world! 👋"
    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("setValueAsync") { (value: String) in
      // Send an event to JavaScript.
      self.sendEvent("onChange", [
        "value": value
      ])
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of the
    // view definition: Prop, Events.
    View(LoqaAudioBridgeModuleView.self) {
      // Defines a setter for the `url` prop.
      Prop("url") { (view: LoqaAudioBridgeModuleView, url: URL) in
        if view.webView.url != url {
          view.webView.load(URLRequest(url: url))
        }
      }

      Events("onLoad")
    }
  }

  // MARK: - Private Helper Functions (v0.2.0 audio capture)

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
    // Options: .allowBluetoothA2DP (support Bluetooth microphones - FIXED FR7)
    try session.setCategory(
      .record,
      mode: .measurement,
      options: [.allowBluetoothA2DP]
    )

    // Activate the audio session
    try session.setActive(true, options: [])
  }

  /// Find closest supported sample rate for iOS
  private func findClosestSupportedRate(requested: Int) -> Int {
    return supportedSampleRates.min(by: { abs($0 - requested) < abs($1 - requested) }) ?? 16000
  }
}
