import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../viewmodel/transcribe_viewmodel.dart';

class TranscribeView extends StatelessWidget {
  const TranscribeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranscribeViewModel>(
      builder: (context, vm, _) {
        final bool isRecording = vm.state == TranscribeState.recording;
        final bool isProcessing = vm.state == TranscribeState.processing;
        final bool isCompleted = vm.state == TranscribeState.completed;
        final bool hasError = vm.state == TranscribeState.error;

        return Scaffold(
          body: Stack(
            children: [
              if (isRecording)
                Positioned.fill(
                  child: AnimatedBackground(
                    child: const SizedBox.expand(),
                  ),
                ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight.clamp(0, double.infinity),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildHeader(context)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: -0.1, end: 0),
                            const SizedBox(height: 40),
                            Center(
                              child: _buildMicButton(context, vm, isRecording, isProcessing)
                                  .animate()
                                  .scale(duration: 300.ms, curve: Curves.easeOut),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: _StatusChip(state: vm.state, error: vm.error)
                                  .animate()
                                  .fadeIn(delay: 200.ms),
                            ),
                            const SizedBox(height: 32),
                            if (isRecording)
                              Center(
                                child: SoundWaveBars(isActive: isRecording)
                                    .animate()
                                    .fadeIn(duration: 300.ms),
                              ),
                            if (isProcessing || isCompleted)
                              _TranscriptCard(
                                text: vm.transcript,
                                isProcessing: isProcessing,
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 24),
                            if (hasError || isCompleted) Center(child: _buildActionButton(context, vm, hasError)),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        GradientText(
          'Voice Capture',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the mic and start speaking.\nYour words will appear instantly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMicButton(
    BuildContext context,
    TranscribeViewModel vm,
    bool isRecording,
    bool isProcessing,
  ) {
    return GestureDetector(
      onTap: () {
        if (isProcessing) return;
        if (isRecording) {
          vm.stop();
        } else {
          vm.start();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isRecording) PulseRings(isActive: isRecording),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isRecording ? 100 : 90,
            height: isRecording ? 100 : 90,
            decoration: BoxDecoration(
              gradient: isRecording ? AppColors.accentGradient : AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isRecording ? AppColors.accent : AppColors.primaryStart)
                      .withOpacity(0.4),
                  blurRadius: isRecording ? 30 : 20,
                  spreadRadius: isRecording ? 5 : 0,
                ),
              ],
            ),
            child: Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: isRecording ? 48 : 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, TranscribeViewModel vm, bool hasError) {
    return GradientButton(
      onPressed: vm.reset,
      height: 52,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasError ? Icons.replay_rounded : Icons.mic_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(hasError ? 'Try Again' : 'Record Again'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state, this.error});

  final TranscribeState state;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    String label;
    Color color;
    IconData icon;

    switch (state) {
      case TranscribeState.recording:
        label = 'Recording...';
        color = AppColors.accent;
        icon = Icons.fiber_manual_record_rounded;
      case TranscribeState.processing:
        label = 'Processing...';
        color = colors.secondary;
        icon = Icons.hourglass_top_rounded;
      case TranscribeState.completed:
        label = 'Done!';
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
      case TranscribeState.error:
        label = error ?? 'Something went wrong';
        color = AppColors.error;
        icon = Icons.error_rounded;
      case TranscribeState.idle:
        label = 'Ready to record';
        color = colors.onSurface.withOpacity(0.5);
        icon = Icons.mic_none_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.text, required this.isProcessing});

  final String text;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientText(
                'Transcript',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (isProcessing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 100),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: text.isEmpty
                ? Text(
                    isProcessing ? 'Transcribing your audio...' : 'No transcript available',
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : SelectableText(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
