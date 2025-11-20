package com.app.speechjammer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.widget.Toast
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.app.speechjammer/audio"
    private var speechJammerChannel: SpeechJammerChannel? = null

    private fun showToast(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        }
    }

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
                "startRecording" -> {
                    showToast("📝 Start recording called")
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        showToast("❌ No file path provided")
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                        return@setMethodCallHandler
                    }
                    val success = channel.startRecording(filePath)
                    if (success) {
                        showToast("✅ Recording started")
                    } else {
                        showToast("❌ Recording failed to start")
                    }
                    result.success(success)
                }
                "stopRecording" -> {
                    showToast("🛑 Stop recording called")
                    val path = channel.stopRecording()
                    if (path != null) {
                        showToast("✅ Recording saved")
                    } else {
                        showToast("❌ No recording to stop")
                    }
                    result.success(path)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
