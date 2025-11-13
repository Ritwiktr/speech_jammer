import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var speechJammer: SpeechJammerChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup Speech Jammer Method Channel
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.speech_jammer/audio",
                                      binaryMessenger: controller.binaryMessenger)
    
    speechJammer = SpeechJammerChannel()
    
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self, let jammer = self.speechJammer else {
        result(FlutterError(code: "UNAVAILABLE", message: "Speech jammer not available", details: nil))
        return
      }
      
      switch call.method {
      case "start":
        if let args = call.arguments as? [String: Any],
           let delayMs = args["delayMs"] as? Int {
          jammer.start(delayMs: delayMs, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "stop":
        jammer.stop(result: result)
        
      case "updateDelay":
        if let args = call.arguments as? [String: Any],
           let delayMs = args["delayMs"] as? Int {
          jammer.updateDelay(delayMs: delayMs, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
