package com.app.speechjammer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.app.speechjammer/audio"
    private var speechJammerChannel: SpeechJammerChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        speechJammerChannel = SpeechJammerChannel()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val delayMs = call.argument<Int>("delayMs") ?: 200
                    // Android native implementation not yet available
                    // Return success to allow app to run
                    result.success(true)
                }
                "stop" -> {
                    result.success(true)
                }
                "updateDelay" -> {
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
