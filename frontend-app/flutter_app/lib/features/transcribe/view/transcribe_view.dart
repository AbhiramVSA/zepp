import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme_notifier.dart';
import '../viewmodel/transcribe_viewmodel.dart';
import '../widgets/pulse_mic_button.dart';
import '../widgets/timed_transcript.dart';
import '../widgets/waveform_visualizer.dart';

class TranscribeView extends StatelessWidget {
  const TranscribeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranscribeViewModel>(
      builder: (context, vm, _) {
        final ThemeNotifier theme = context.read<ThemeNotifier>();
        final ThemeMode mode = context.watch<ThemeNotifier>().mode;
        final bool isRecording = vm.state == TranscribeState.recording;
        final bool isProcessing = vm.state == TranscribeState.processing;
        final bool isCompleted = vm.state == TranscribeState.completed;
        final bool hasError = vm.state == TranscribeState.error;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Live Transcribe'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Toggle theme',
                onPressed: theme.toggle,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset',
                onPressed: isRecording ? null : vm.reset,
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight.clamp(0, double.infinity)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'Speak naturally',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hold to capture. We stream raw PCM to the server and return your transcript instantly.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: WaveformVisualizer(key: ValueKey<bool>(isRecording), isActive: isRecording),
                        ),
                        const SizedBox(height: 32),
                        PulseMicButton(
                          isRecording: isRecording,
                          onTap: () {
                            if (isProcessing) return;
                            if (isRecording) {
                              vm.stop();
                            } else {
                              vm.start();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _StatusLabel(key: ValueKey(vm.state), state: vm.state, error: vm.error),
                        ),
                        const SizedBox(height: 32),
                        TimedTranscript(
                          text: vm.transcript.isEmpty ? '' : vm.transcript,
                          visible: isProcessing || isCompleted,
                        ),
                        const SizedBox(height: 24),
                        if (hasError)
                          FilledButton.icon(
                            onPressed: vm.reset,
                            icon: const Icon(Icons.replay),
                            label: const Text('Try Again'),
                          )
                        else if (isCompleted)
                          FilledButton.icon(
                            onPressed: vm.reset,
                            icon: const Icon(Icons.mic),
                            label: const Text('Record Again'),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({Key? key, required this.state, this.error}) : super(key: key);

  final TranscribeState state;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    String label;
    Color color;

    switch (state) {
      case TranscribeState.recording:
        label = 'Recording...';
        color = colors.primary;
        break;
      case TranscribeState.processing:
        label = 'Processing audio...';
        color = colors.secondary;
        break;
      case TranscribeState.completed:
        label = 'Completed';
        color = colors.tertiary;
        break;
      case TranscribeState.error:
        label = error ?? 'Something went wrong';
        color = colors.error;
        break;
      case TranscribeState.idle:
        label = 'Ready to record';
        color = colors.onSurfaceVariant;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}
