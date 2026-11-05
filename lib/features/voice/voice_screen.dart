import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/flow_page.dart';

/// 21 · Voice control, shown as a preview only: nothing listens or acts
/// (spec 012). The example phrase is labelled as an example.
class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final home = context.app.homes.activeHome;
    return FlowPage(
      top: FlowTopBar(
        leading: const CalmBackButton(close: true),
        center: Column(
          children: [
            Text(
              l10n.voiceControl,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (home != null)
              Text(home.name, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.voiceTryExamples,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          InfoNote(
            icon: CupertinoIcons.lock_shield,
            tone: NoteTone.warm,
            text: l10n.voiceNoUnlock,
          ),
        ],
      ),
      children: [
        const SizedBox(height: 32),
        const Center(child: _ListeningOrb()),
        const SizedBox(height: 24),
        Center(child: StatusBadge(l10n.preview, subtle: true)),
        const SizedBox(height: 12),
        Text(
          l10n.voiceExamplePhrase,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 22),
        CalmPanel(
          color: palette.glow,
          child: Row(
            children: [
              Icon(CupertinoIcons.lightbulb_fill, color: palette.goldDeep),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.voiceExampleTarget,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.voiceExampleResult,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InfoNote(text: l10n.voiceNotInPreview),
      ],
    );
  }
}

/// Soft breathing rings around a mic. Still under Reduce Motion.
class _ListeningOrb extends StatefulWidget {
  const _ListeningOrb();

  @override
  State<_ListeningOrb> createState() => _ListeningOrbState();
}

class _ListeningOrbState extends State<_ListeningOrb>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 200,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in [0.0, .5])
                _Ring(
                  progress: (_controller.value + offset) % 1,
                  color: palette.accentSoft,
                ),
              child!,
            ],
          ),
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.strong,
            ),
            child: Icon(CupertinoIcons.mic_fill, size: 40, color: palette.gold),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 104 + 96 * progress;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: (1 - progress) * .6),
          width: 2,
        ),
      ),
    );
  }
}
