package com.app.speechjammer

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.AudioManager
import android.media.MediaRecorder
import android.util.Log
import kotlin.concurrent.thread

class SpeechJammerChannel {
    private val TAG = "SpeechJammerChannel"
    
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var isRunning = false
    private var audioThread: Thread? = null
    
    private var delayMs: Int = 200
    private var delayBuffer: FloatArray? = null
    private var bufferSize: Int = 0
    private var writeIndex: Int = 0
    private var readIndex: Int = 0
    
    private val sampleRate = 44100
    private val channelConfig = AudioFormat.CHANNEL_IN_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    
    fun start(delayMs: Int): Boolean {
        if (isRunning) {
            Log.d(TAG, "Already running")
            return true
        }
        
        this.delayMs = delayMs
        
        try {
            // Calculate buffer sizes
            val minRecordBufferSize = AudioRecord.getMinBufferSize(
                sampleRate,
                channelConfig,
                audioFormat
            )
            
            val minTrackBufferSize = AudioTrack.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                audioFormat
            )
            
            if (minRecordBufferSize == AudioRecord.ERROR || 
                minRecordBufferSize == AudioRecord.ERROR_BAD_VALUE ||
                minTrackBufferSize == AudioTrack.ERROR || 
                minTrackBufferSize == AudioTrack.ERROR_BAD_VALUE) {
                Log.e(TAG, "Invalid buffer size")
                return false
            }
            
            // Use larger buffer for better stability
            val recordBufferSize = minRecordBufferSize * 4
            val trackBufferSize = minTrackBufferSize * 4
            
            // Initialize delay buffer (minimum 1024 samples)
            bufferSize = maxOf(1024, (sampleRate * delayMs) / 1000)
            delayBuffer = FloatArray(bufferSize) { 0f }
            writeIndex = 0
            readIndex = 0
            
            Log.d(TAG, "Record buffer: $recordBufferSize, Track buffer: $trackBufferSize, Delay buffer: $bufferSize")
            
            // Create AudioRecord
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                audioFormat,
                recordBufferSize
            )
            
            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed")
                cleanup()
                return false
            }
            
            // Create AudioTrack
            audioTrack = AudioTrack.Builder()
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .setEncoding(audioFormat)
                        .build()
                )
                .setBufferSizeInBytes(trackBufferSize)
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()
            
            if (audioTrack?.state != AudioTrack.STATE_INITIALIZED) {
                Log.e(TAG, "AudioTrack initialization failed")
                cleanup()
                return false
            }
            
            // Start recording and playing
            audioRecord?.startRecording()
            audioTrack?.play()
            
            isRunning = true
            
            // Start audio processing thread
            audioThread = thread {
                processAudio()
            }
            
            Log.d(TAG, "✅ Speech jammer started with ${delayMs}ms delay")
            return true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting speech jammer: ${e.message}", e)
            cleanup()
            return false
        }
    }
    
    private fun processAudio() {
        val bufferSize = 1024
        val audioBuffer = ShortArray(bufferSize)
        
        Log.d(TAG, "🎵 Audio processing thread started")
        
        while (isRunning) {
            try {
                // Read from microphone
                val readCount = audioRecord?.read(audioBuffer, 0, bufferSize) ?: 0
                
                if (readCount > 0) {
                    // Process each sample
                    for (i in 0 until readCount) {
                        // Convert to float (-1.0 to 1.0)
                        val sample = audioBuffer[i].toFloat() / Short.MAX_VALUE.toFloat()
                        
                        // Write to delay buffer
                        delayBuffer?.set(writeIndex, sample)
                        writeIndex = (writeIndex + 1) % this.bufferSize
                        
                        // Read from delay buffer (delayed sample)
                        val delayedSample = delayBuffer?.get(readIndex) ?: 0f
                        readIndex = (readIndex + 1) % this.bufferSize
                        
                        // Convert back to Short for playback
                        audioBuffer[i] = (delayedSample * Short.MAX_VALUE.toFloat()).toInt().toShort()
                    }
                    
                    // Write to speakers
                    audioTrack?.write(audioBuffer, 0, readCount)
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error in audio processing: ${e.message}")
                if (!isRunning) break
            }
        }
        
        Log.d(TAG, "🎵 Audio processing thread stopped")
    }
    
    fun stop(): Boolean {
        if (!isRunning) {
            Log.d(TAG, "Already stopped")
            return true
        }
        
        Log.d(TAG, "⏹️ Stopping speech jammer...")
        isRunning = false
        
        // Wait for thread to finish
        audioThread?.join(1000)
        
        cleanup()
        
        Log.d(TAG, "✅ Speech jammer stopped")
        return true
    }
    
    fun updateDelay(delayMs: Int): Boolean {
        this.delayMs = delayMs
        
        // Recalculate buffer size (minimum 1024 samples)
        val newBufferSize = maxOf(1024, (sampleRate * delayMs) / 1000)
        
        // Resize delay buffer
        bufferSize = newBufferSize
        delayBuffer = FloatArray(bufferSize) { 0f }
        writeIndex = 0
        readIndex = 0
        
        Log.d(TAG, "🔄 Delay updated to ${delayMs}ms, buffer size: $bufferSize")
        return true
    }
    
    private fun cleanup() {
        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
            
            audioTrack?.stop()
            audioTrack?.release()
            audioTrack = null
            
            delayBuffer = null
            
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup: ${e.message}")
        }
    }
}
