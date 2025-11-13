import 'package:equatable/equatable.dart';

abstract class SpeechJammerEvent extends Equatable {
  const SpeechJammerEvent();

  @override
  List<Object?> get props => [];
}

class InitializeJammer extends SpeechJammerEvent {}

class StartJammer extends SpeechJammerEvent {}

class StopJammer extends SpeechJammerEvent {}

class UpdateDelay extends SpeechJammerEvent {
  final int delayMs;

  const UpdateDelay(this.delayMs);

  @override
  List<Object?> get props => [delayMs];
}

class StartRecording extends SpeechJammerEvent {}

class StopRecording extends SpeechJammerEvent {}

class CheckHeadphones extends SpeechJammerEvent {}

