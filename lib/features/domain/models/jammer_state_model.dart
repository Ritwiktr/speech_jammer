import 'package:equatable/equatable.dart';

enum JammerStatus {
  idle,
  starting,
  active,
  stopping,
  recording,
}

class JammerStateModel extends Equatable {
  final JammerStatus status;
  final int delayMs;
  final bool isRecording;
  final bool headphonesConnected;
  final String? errorMessage;
  final String? recordingPath;

  const JammerStateModel({
    required this.status,
    required this.delayMs,
    this.isRecording = false,
    this.headphonesConnected = true,
    this.errorMessage,
    this.recordingPath,
  });

  factory JammerStateModel.initial() {
    return const JammerStateModel(
      status: JammerStatus.idle,
      delayMs: 200,
      isRecording: false,
      headphonesConnected: true,
    );
  }

  JammerStateModel copyWith({
    JammerStatus? status,
    int? delayMs,
    bool? isRecording,
    bool? headphonesConnected,
    String? errorMessage,
    String? recordingPath,
  }) {
    return JammerStateModel(
      status: status ?? this.status,
      delayMs: delayMs ?? this.delayMs,
      isRecording: isRecording ?? this.isRecording,
      headphonesConnected: headphonesConnected ?? this.headphonesConnected,
      errorMessage: errorMessage ?? this.errorMessage,
      recordingPath: recordingPath ?? this.recordingPath,
    );
  }

  @override
  List<Object?> get props => [
        status,
        delayMs,
        isRecording,
        headphonesConnected,
        errorMessage,
        recordingPath,
      ];
}

