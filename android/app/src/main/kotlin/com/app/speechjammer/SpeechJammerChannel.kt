package com.app.speechjammer

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.AudioManager
import android.media.MediaRecorder
import android.util.Log
import kotlin.concurrent.thread
import java.io.File
import java.io.FileOutputStream
import java.io.FileInputStream
import java.io.RandomAccessFile

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
    
    // Recording
    private var isRecording = false
    private var recordingFile: File? = null
    private var recordingTempFile: File? = null
    private var recordingOutputStream: FileOutputStream? = null
    
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
                    // Save original audio if recording (write directly to file to avoid memory issues)
                    if (isRecording && recordingOutputStream != null) {
                        try {
                            for (i in 0 until readCount) {
                                // Write 16-bit sample in little-endian format
                                val sample = audioBuffer[i].toInt()
                                recordingOutputStream?.write(sample and 0xFF)
                                recordingOutputStream?.write((sample shr 8) and 0xFF)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error writing audio data: ${e.message}")
                        }
                    }
                    
                    // Process each sample for delayed feedback
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
    
    fun startRecording(filePath: String): Boolean {
        if (!isRunning) {
            Log.e(TAG, "Cannot start recording - jammer is not running")
            return false
        }
        
        if (isRecording) {
            Log.d(TAG, "Already recording")
            return true
        }
        
        try {
            recordingFile = File(filePath)
            // Create temp file for raw PCM data
            recordingTempFile = File(filePath + ".tmp")
            recordingOutputStream = FileOutputStream(recordingTempFile)
            isRecording = true
            Log.d(TAG, "🎙️ Recording started to: $filePath")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error starting recording: ${e.message}", e)
            isRecording = false
            recordingOutputStream?.close()
            recordingOutputStream = null
            recordingTempFile?.delete()
            recordingTempFile = null
            return false
        }
    }
    
    fun stopRecording(): String? {
        if (!isRecording) {
            Log.d(TAG, "Not recording")
            return null
        }
        
        isRecording = false
        
        try {
            // Close the output stream
            recordingOutputStream?.flush()
            recordingOutputStream?.close()
            recordingOutputStream = null
            
            val file = recordingFile ?: return null
            val tempFile = recordingTempFile ?: return null
            
            if (!tempFile.exists()) {
                Log.e(TAG, "Temp file doesn't exist")
                return null
            }
            
            val dataSize = tempFile.length().toInt()
            val sampleCount = dataSize / 2
            
            Log.d(TAG, "💾 Converting PCM to WAV: $sampleCount samples ($dataSize bytes)...")
            
            // Write WAV file by streaming data without loading all into memory
            RandomAccessFile(file, "rw").use { wavFile ->
                val channels = 1
                val bitsPerSample = 16
                val byteRate = sampleRate * channels * bitsPerSample / 8
                
                // Write WAV header
                wavFile.writeBytes("RIFF")
                writeIntLE(wavFile, 36 + dataSize)
                wavFile.writeBytes("WAVE")
                
                // fmt chunk
                wavFile.writeBytes("fmt ")
                writeIntLE(wavFile, 16)
                writeShortLE(wavFile, 1) // PCM
                writeShortLE(wavFile, channels)
                writeIntLE(wavFile, sampleRate)
                writeIntLE(wavFile, byteRate)
                writeShortLE(wavFile, channels * bitsPerSample / 8)
                writeShortLE(wavFile, bitsPerSample)
                
                // data chunk
                wavFile.writeBytes("data")
                writeIntLE(wavFile, dataSize)
                
                // Copy PCM data from temp file in chunks (no memory load!)
                FileInputStream(tempFile).use { input ->
                    val buffer = ByteArray(8192) // 8KB chunks
                    var bytesRead: Int
                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        wavFile.write(buffer, 0, bytesRead)
                    }
                }
            }
            
            // Clean up temp file
            tempFile.delete()
            recordingTempFile = null
            
            val path = file.absolutePath
            recordingFile = null
            
            Log.d(TAG, "✅ Recording saved to: $path (${File(path).length() / 1024} KB)")
            return path
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording: ${e.message}", e)
            recordingOutputStream?.close()
            recordingOutputStream = null
            recordingTempFile?.delete()
            recordingTempFile = null
            recordingFile = null
            return null
        }
    }
    
    // Helper function to write 16-bit little-endian
    private fun writeShortLE(raf: RandomAccessFile, value: Int) {
        raf.write(value and 0xFF)
        raf.write((value shr 8) and 0xFF)
    }
    
    // Helper function to write 32-bit little-endian
    private fun writeIntLE(raf: RandomAccessFile, value: Int) {
        raf.write(value and 0xFF)
        raf.write((value shr 8) and 0xFF)
        raf.write((value shr 16) and 0xFF)
        raf.write((value shr 24) and 0xFF)
    }
    
    private fun cleanup() {
        try {
            // Stop recording if active
            if (isRecording) {
                stopRecording()
            }
            
            // Clean up any leftover recording resources
            recordingOutputStream?.close()
            recordingOutputStream = null
            recordingTempFile?.delete()
            recordingTempFile = null
            recordingFile = null
            
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
