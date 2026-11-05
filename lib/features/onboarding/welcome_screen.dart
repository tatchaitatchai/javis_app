import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/motion/entrance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/flow_page.dart';
import '../../core/widgets/home_glow_mark.dart';
import 'phone_screen.dart';

/// 01 · Welcome.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return FlowPage(
      top: const Align(
        alignment: Alignment.centerRight,
        child: LanguageButton(),
      ),
      footer: Entrance(
        order: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: l10n.startWithPhone,
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(builder: (_) => const PhoneScreen()),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.termsNotice,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      children: [
        const SizedBox(height: 32),
        const Entrance(child: Center(child: HomeGlowMark(size: 152))),
        const SizedBox(height: 28),
        Entrance(
          order: 1,
          child: Text(
            'JAVIS',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontFamily: 'Georgia',
              fontSize: 40,
              letterSpacing: 4.8,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Entrance(
          order: 2,
          child: Text(
            l10n.welcomeTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.6,
              color: palette.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Entrance(
          order: 3,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final point in [
                  l10n.welcomePointHomes,
                  l10n.welcomePointMembers,
                  l10n.welcomePointScenes,
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            point,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
