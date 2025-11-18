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
            val channel = speechJammerChannel
            if (channel == null) {
                result.error("UNAVAILABLE", "Speech jammer not available", null)
                return@setMethodCallHandler
            }
            
            when (call.method) {
                "start" -> {
                    val delayMs = call.argument<Int>("delayMs") ?: 200
                    val success = channel.start(delayMs)
                    result.success(success)
                }
                "stop" -> {
                    val success = channel.stop()
                    result.success(success)
                }
                "updateDelay" -> {
                    val delayMs = call.argument<Int>("delayMs") ?: 200
                    val success = channel.updateDelay(delayMs)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
