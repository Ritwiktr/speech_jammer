import 'package:equatable/equatable.dart';
import '../../domain/models/jammer_state_model.dart';

abstract class SpeechJammerState extends Equatable {
  const SpeechJammerState();

  @override
  List<Object?> get props => [];
}

class SpeechJammerInitial extends SpeechJammerState {}

class SpeechJammerLoading extends SpeechJammerState {}

class SpeechJammerReady extends SpeechJammerState {
  final JammerStateModel model;

  const SpeechJammerReady(this.model);

  @override
  List<Object?> get props => [model];
}

class SpeechJammerError extends SpeechJammerState {
  final String message;

  const SpeechJammerError(this.message);

  @override
  List<Object?> get props => [message];
}

