# Speech Jammer App

A Flutter application that implements delayed auditory feedback (DAF) to create a speech jamming effect. This app works on both Android and iOS platforms.

## Features

- ✅ **Adjustable Delay Slider**: Control the delay time from 0ms to 500ms for optimal speech jamming effect
- ✅ **Live Voice Echo**: Real-time audio feedback through microphone and headphones
- ✅ **Clean Modern UI**: Simple, intuitive interface with start/stop button and delay control
- ✅ **Headphone Detection**: Automatic detection with warnings if headphones are not connected
- ✅ **Session Recording**: Option to record your speech jamming sessions
- ✅ **Cross-Platform**: Works on both Android and iOS devices

## Project Structure

The app follows clean architecture principles with the following structure:

```
lib/
├── core/
│   ├── constants/        # App-wide constants
│   ├── database/         # Database implementations (if needed)
│   ├── error/           # Error handling and failures
│   ├── routes/          # App routing configuration
│   ├── services/        # Core services
│   ├── themes/          # App theming
│   ├── utils/           # Utility functions
│   └── widgets/         # Reusable widgets
├── features/
│   ├── application/     # Business logic and services
│   ├── domain/          # Domain models and entities
│   └── presentation/    # UI layer (screens, widgets, BLoC)
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode for mobile development
- Physical device or emulator with headphones support

### Installation

1. Clone the repository
2. Navigate to the project directory:
   ```bash
   cd speech_jammer
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Permissions

### Android
The app requires the following permissions (already configured in AndroidManifest.xml):
- `RECORD_AUDIO`: For microphone access
- `WRITE_EXTERNAL_STORAGE`: For saving recordings
- `READ_EXTERNAL_STORAGE`: For accessing recordings
- `MODIFY_AUDIO_SETTINGS`: For audio configuration

### iOS
The app requires microphone permission (configured in Info.plist):
- `NSMicrophoneUsageDescription`: For microphone access

## Usage

1. **Connect Headphones**: Make sure headphones or earphones are connected
2. **Adjust Delay**: Use the slider to set your preferred delay (default: 200ms)
3. **Start Jammer**: Tap the play button to start the speech jamming effect
4. **Speak**: Try speaking normally - you'll experience the DAF effect
5. **Record (Optional)**: Tap the record button to save your session
6. **Stop**: Tap the stop button when done

## How It Works

The Speech Jammer uses **Delayed Auditory Feedback (DAF)**, a phenomenon where hearing your own voice with a slight delay (typically 100-300ms) makes it difficult to speak fluently. The app:

1. Captures audio from your microphone
2. Applies a configurable delay
3. Plays the delayed audio back through headphones
4. Creates a feedback loop that disrupts speech patterns

## Dependencies

- `flutter_bloc`: State management
- `equatable`: Value equality
- `permission_handler`: Handling runtime permissions
- `record`: Audio recording
- `just_audio`: Audio playback
- `audio_session`: Audio session management
- `path_provider`: File system paths

## Note on Real-Time Audio

The current implementation uses Flutter's audio packages. For production-grade, low-latency audio processing, you would need to implement platform-specific code using:
- **Android**: AudioTrack and AudioRecord APIs
- **iOS**: AVAudioEngine and Audio Units

This would require Method Channels to bridge between Flutter and native code.

## Future Enhancements

- [ ] Real-time audio processing with native code
- [ ] Advanced headphone detection
- [ ] Multiple delay presets
- [ ] Visualization of audio waveforms
- [ ] Playback of recorded sessions
- [ ] Share recordings
- [ ] Statistics and analytics

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Disclaimer

This app is for educational and entertainment purposes. The speech jamming effect can be disorienting. Use responsibly and do not use while driving or operating machinery.
