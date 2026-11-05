import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import 'home_glow_mark.dart';

/// Keeps the app mounted while the finite launch animation reveals it.
class LaunchExperience extends StatefulWidget {
  const LaunchExperience({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<LaunchExperience> createState() => _LaunchExperienceState();
}

class _LaunchExperienceState extends State<LaunchExperience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
        }
      });
  bool _started = false;
  bool _finished = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.enabled) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = Duration(milliseconds: _reduceMotion ? 450 : 1400);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showing = widget.enabled && !_finished;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: showing,
          child: IgnorePointer(ignoring: showing, child: widget.child),
        ),
        if (showing)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final fade = Curves.easeInOut.transform(
                  ((_controller.value - (_reduceMotion ? .3 : .76)) /
                          (_reduceMotion ? .7 : .24))
                      .clamp(0.0, 1.0),
                );
                return Opacity(
                  opacity: 1 - fade,
                  child: _LaunchSurface(
                    progress: _reduceMotion ? 0 : _controller.value,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LaunchSurface extends StatelessWidget {
  const _LaunchSurface({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('javis-splash'),
      color: scheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HomeGlowMark(
                      size: math.min(200, constraints.maxWidth - 64),
                      // The light swells once and settles before the splash
                      // fades out at 76% of the animation.
                      swell: math.sin(
                        math.pi * (progress / .76).clamp(0.0, 1.0),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Spaced glyphs match the native LaunchScreen label at the
                    // handoff. UIKit tracks SF tighter than Flutter, so the
                    // negative spacing was measured on an iPhone simulator.
                    Semantics(
                      label: 'JAVIS',
                      excludeSemantics: true,
                      child: Text(
                        'J A V I S',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'System',
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1.35,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.harmony,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        // Matches UIKit's SF tracking on the native frame.
                        letterSpacing: context.l10n.isThai ? null : -.09,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
