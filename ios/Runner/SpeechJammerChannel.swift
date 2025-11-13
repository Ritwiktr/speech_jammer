import Flutter
import AVFoundation
import Accelerate

class SpeechJammerChannel: NSObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var playerNode: AVAudioPlayerNode?
    private var delayMs: Int = 200
    private var isActive = false
    
    // Circular buffer for delay
    private var delayBuffer: [Float] = []
    private var bufferSize: Int = 0
    private var writeIndex: Int = 0
    private var readIndex: Int = 0
    
    func setup(delayMs: Int) {
        self.delayMs = delayMs
        
        // Calculate buffer size based on delay and sample rate
        let sampleRate = 44100.0
        // Minimum buffer size of 1024 samples to avoid crashes
        bufferSize = max(1024, Int((Double(delayMs) / 1000.0) * sampleRate))
        delayBuffer = Array(repeating: 0.0, count: bufferSize)
        writeIndex = 0
        readIndex = 0
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, 
                                        mode: .measurement,
                                        options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \\(error)")
        }
    }
    
    func start(delayMs: Int, result: @escaping FlutterResult) {
        guard !isActive else {
            result(FlutterError(code: "ALREADY_ACTIVE", 
                              message: "Speech jammer already active", 
                              details: nil))
            return
        }
        
        setup(delayMs: delayMs)
        
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            result(FlutterError(code: "ENGINE_ERROR", 
                              message: "Failed to create audio engine", 
                              details: nil))
            return
        }
        
        inputNode = engine.inputNode
        playerNode = AVAudioPlayerNode()
        
        guard let input = inputNode, let player = playerNode else {
            result(FlutterError(code: "NODE_ERROR", 
                              message: "Failed to create audio nodes", 
                              details: nil))
            return
        }
        
        engine.attach(player)
        
        // Get the input format
        let inputFormat = input.inputFormat(forBus: 0)
        let sampleRate = inputFormat.sampleRate
        let channels = inputFormat.channelCount
        
        // Create output format
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                        sampleRate: sampleRate,
                                        channels: channels,
                                        interleaved: false)
        
        guard let format = outputFormat else {
            result(FlutterError(code: "FORMAT_ERROR", 
                              message: "Failed to create audio format", 
                              details: nil))
            return
        }
        
        // Connect player to output
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // Install tap on input
        input.installTap(onBus: 0, 
                        bufferSize: 1024, 
                        format: inputFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            
            // Convert buffer to float array
            guard let channelData = buffer.floatChannelData else { return }
            let frameLength = Int(buffer.frameLength)
            let channelDataValue = channelData[0]
            
            // Process audio with delay
            for i in 0..<frameLength {
                // Write to delay buffer
                self.delayBuffer[self.writeIndex] = channelDataValue[i]
                self.writeIndex = (self.writeIndex + 1) % self.bufferSize
                
                // Read from delay buffer
                let delayedSample = self.delayBuffer[self.readIndex]
                self.readIndex = (self.readIndex + 1) % self.bufferSize
                
                // Write delayed audio to output buffer
                channelDataValue[i] = delayedSample
            }
            
            // Play the delayed audio
            player.scheduleBuffer(buffer, completionHandler: nil)
        }
        
        // Start the audio engine
        do {
            try engine.start()
            player.play()
            isActive = true
            result(true)
        } catch {
            result(FlutterError(code: "START_ERROR", 
                              message: "Failed to start audio engine: \\(error)", 
                              details: nil))
        }
    }
    
    func stop(result: @escaping FlutterResult) {
        guard isActive else {
            result(false)
            return
        }
        
        inputNode?.removeTap(onBus: 0)
        playerNode?.stop()
        audioEngine?.stop()
        
        audioEngine = nil
        inputNode = nil
        playerNode = nil
        isActive = false
        
        result(true)
    }
    
    func updateDelay(delayMs: Int, result: @escaping FlutterResult) {
        self.delayMs = delayMs
        
        // Recalculate buffer size
        let sampleRate = 44100.0
        // Minimum buffer size of 1024 samples to avoid crashes
        let newBufferSize = max(1024, Int((Double(delayMs) / 1000.0) * sampleRate))
        
        // Resize delay buffer
        bufferSize = newBufferSize
        delayBuffer = Array(repeating: 0.0, count: bufferSize)
        writeIndex = 0
        readIndex = 0
        
        result(true)
    }
}

