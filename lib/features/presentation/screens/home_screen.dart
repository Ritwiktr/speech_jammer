import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/themes/theme_controller.dart';
import '../../domain/models/jammer_state_model.dart';
import '../bloc/speech_jammer_bloc.dart';
import '../bloc/speech_jammer_event.dart';
import '../bloc/speech_jammer_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          Consumer<ThemeController>(
            builder: (context, themeController, _) {
              return PopupMenuButton<ThemeMode>(
                icon: Icon(
                  themeController.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                tooltip: 'Theme: ${themeController.themeModeString}',
                onSelected: (ThemeMode mode) {
                  themeController.setThemeMode(mode);
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<ThemeMode>>[
                  PopupMenuItem<ThemeMode>(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        const Icon(Icons.light_mode),
                        const SizedBox(width: 12),
                        const Text('Light'),
                        if (themeController.themeMode == ThemeMode.light)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 20),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem<ThemeMode>(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        const Icon(Icons.dark_mode),
                        const SizedBox(width: 12),
                        const Text('Dark'),
                        if (themeController.themeMode == ThemeMode.dark)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 20),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem<ThemeMode>(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        const Icon(Icons.settings_suggest),
                        const SizedBox(width: 12),
                        const Text('System'),
                        if (themeController.themeMode == ThemeMode.system)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 20),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<SpeechJammerBloc, SpeechJammerState>(
        listener: (context, state) {
          if (state is SpeechJammerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () async {
                    await openAppSettings();
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (state is SpeechJammerReady) {
            if (!state.model.headphonesConnected &&
                state.model.status == JammerStatus.idle) {
              _showHeadphoneWarning(context);
            }
            if (state.model.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.model.errorMessage!),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () async {
                      await openAppSettings();
                    },
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is SpeechJammerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SpeechJammerReady) {
            return _buildContent(context, state.model);
          }

          return const Center(child: Text('Initializing...'));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, JammerStateModel model) {
    final theme = Theme.of(context);
    final isActive = model.status == JammerStatus.active ||
        model.status == JammerStatus.starting;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          children: [
            // Status Cards
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Status',
                    value: _getStatusText(model.status),
                    icon: Icons.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Delay',
                    value: '${model.delayMs} ms',
                    icon: Icons.timer,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Headphone Status
            Card(
              color: model.headphonesConnected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      model.headphonesConnected
                          ? Icons.headset
                          : Icons.headset_off,
                      color: model.headphonesConnected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      model.headphonesConnected
                          ? 'Headphones Connected'
                          : 'Headphones Not Detected',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: model.headphonesConnected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Main Control Button
            Column(
              children: [
                CustomButton(
                  onPressed: () {
                    final bloc = context.read<SpeechJammerBloc>();
                    if (isActive) {
                      bloc.add(StopJammer());
                    } else {
                      bloc.add(StartJammer());
                    }
                  },
                  icon: isActive ? Icons.stop : Icons.play_arrow,
                  isActive: isActive,
                  color: isActive ? Colors.red : theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  isActive ? 'Stop Jammer' : 'Start Jammer',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),

            const Spacer(),

            // Delay Slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjust Delay',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('${AppConstants.minDelayMs}ms'),
                        Expanded(
                          child: Slider(
                            value: model.delayMs.toDouble(),
                            min: AppConstants.minDelayMs.toDouble(),
                            max: AppConstants.maxDelayMs.toDouble(),
                            divisions: 50,
                            label: '${model.delayMs}ms',
                            onChanged: isActive
                                ? null
                                : (value) {
                                    context.read<SpeechJammerBloc>().add(
                                          UpdateDelay(value.toInt()),
                                        );
                                  },
                          ),
                        ),
                        const Text('${AppConstants.maxDelayMs}ms'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recording Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isActive
                      ? () {
                          final bloc = context.read<SpeechJammerBloc>();
                          if (model.isRecording) {
                            bloc.add(StopRecording());
                          } else {
                            bloc.add(StartRecording());
                          }
                        }
                      : null,
                  icon: Icon(
                    model.isRecording ? Icons.stop : Icons.fiber_manual_record,
                  ),
                  label: Text(
                    model.isRecording ? 'Stop Recording' : 'Record Session',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: model.isRecording ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(JammerStatus status) {
    switch (status) {
      case JammerStatus.idle:
        return 'Idle';
      case JammerStatus.starting:
        return 'Starting...';
      case JammerStatus.active:
        return 'Active';
      case JammerStatus.stopping:
        return 'Stopping...';
      case JammerStatus.recording:
        return 'Recording';
    }
  }

  void _showHeadphoneWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.headphoneWarningTitle),
        content: const Text(AppConstants.headphoneWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
