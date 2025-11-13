import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/speech_jammer_service.dart';
import '../../domain/models/jammer_state_model.dart';
import 'speech_jammer_event.dart';
import 'speech_jammer_state.dart';

class SpeechJammerBloc extends Bloc<SpeechJammerEvent, SpeechJammerState> {
  final SpeechJammerService speechJammerService;
  JammerStateModel _currentModel = JammerStateModel.initial();

  SpeechJammerBloc({required this.speechJammerService})
      : super(SpeechJammerInitial()) {
    on<InitializeJammer>(_onInitialize);
    on<StartJammer>(_onStart);
    on<StopJammer>(_onStop);
    on<UpdateDelay>(_onUpdateDelay);
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<CheckHeadphones>(_onCheckHeadphones);

    // Auto-initialize
    add(InitializeJammer());
  }

  Future<void> _onInitialize(
    InitializeJammer event,
    Emitter<SpeechJammerState> emit,
  ) async {
    // Immediately show UI
    emit(SpeechJammerReady(_currentModel));

    try {
      print('🚀 Starting initialization...');

      // Initialize and get permissions
      final initialized = await speechJammerService.initialize();
      print('✅ Initialization result: $initialized');

      if (emit.isDone) return; // Check if emit is still valid

      // Check headphones
      final headphonesConnected = await speechJammerService.checkHeadphones();
      print('🎧 Headphones connected: $headphonesConnected');

      if (emit.isDone) return; // Check again before emitting

      _currentModel = _currentModel.copyWith(
        headphonesConnected: headphonesConnected,
      );
      emit(SpeechJammerReady(_currentModel));
      print('✨ Updated state emitted');
    } catch (e) {
      print('❌ Error in initialization: $e');
      if (!emit.isDone) {
        // Only emit error if handler is still active
        _currentModel = _currentModel.copyWith(
          errorMessage: 'Initialization failed: ${e.toString()}',
        );
        emit(SpeechJammerReady(_currentModel));
      }
    }
  }

  Future<void> _onStart(
    StartJammer event,
    Emitter<SpeechJammerState> emit,
  ) async {
    try {
      _currentModel = _currentModel.copyWith(status: JammerStatus.starting);
      emit(SpeechJammerReady(_currentModel));

      await speechJammerService.start(_currentModel.delayMs);

      _currentModel = _currentModel.copyWith(status: JammerStatus.active);
      emit(SpeechJammerReady(_currentModel));
    } catch (e) {
      _currentModel = _currentModel.copyWith(
        status: JammerStatus.idle,
        errorMessage: e.toString(),
      );
      emit(SpeechJammerReady(_currentModel));
    }
  }

  Future<void> _onStop(
    StopJammer event,
    Emitter<SpeechJammerState> emit,
  ) async {
    try {
      _currentModel = _currentModel.copyWith(status: JammerStatus.stopping);
      emit(SpeechJammerReady(_currentModel));

      await speechJammerService.stop();

      _currentModel = _currentModel.copyWith(
        status: JammerStatus.idle,
        isRecording: false,
      );
      emit(SpeechJammerReady(_currentModel));
    } catch (e) {
      _currentModel = _currentModel.copyWith(errorMessage: e.toString());
      emit(SpeechJammerReady(_currentModel));
    }
  }

  Future<void> _onUpdateDelay(
    UpdateDelay event,
    Emitter<SpeechJammerState> emit,
  ) async {
    _currentModel = _currentModel.copyWith(delayMs: event.delayMs);
    await speechJammerService.updateDelay(event.delayMs);
    emit(SpeechJammerReady(_currentModel));
  }

  Future<void> _onStartRecording(
    StartRecording event,
    Emitter<SpeechJammerState> emit,
  ) async {
    try {
      final path = await speechJammerService.startRecording();
      if (path != null) {
        _currentModel = _currentModel.copyWith(
          isRecording: true,
          recordingPath: path,
        );
        emit(SpeechJammerReady(_currentModel));
      }
    } catch (e) {
      _currentModel = _currentModel.copyWith(errorMessage: e.toString());
      emit(SpeechJammerReady(_currentModel));
    }
  }

  Future<void> _onStopRecording(
    StopRecording event,
    Emitter<SpeechJammerState> emit,
  ) async {
    try {
      await speechJammerService.stopRecording();
      _currentModel = _currentModel.copyWith(isRecording: false);
      emit(SpeechJammerReady(_currentModel));
    } catch (e) {
      _currentModel = _currentModel.copyWith(errorMessage: e.toString());
      emit(SpeechJammerReady(_currentModel));
    }
  }

  Future<void> _onCheckHeadphones(
    CheckHeadphones event,
    Emitter<SpeechJammerState> emit,
  ) async {
    final headphonesConnected = await speechJammerService.checkHeadphones();
    _currentModel = _currentModel.copyWith(
      headphonesConnected: headphonesConnected,
    );
    emit(SpeechJammerReady(_currentModel));
  }

  @override
  Future<void> close() {
    speechJammerService.dispose();
    return super.close();
  }
}
