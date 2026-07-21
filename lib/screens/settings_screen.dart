import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/onboarding_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/pk_tokens.dart';
import '../widgets/pk_card.dart';
import '../widgets/pk_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.pkSpacing;

    return PkScaffold(
      title: 'Ajustes',
      child: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: spacing.sm),
          const Text(
            'Preferencias locales. En este slice no se reproduce audio real.',
          ),
          SizedBox(height: spacing.lg),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return PkCard(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Sonidos'),
                        subtitle: const Text(
                          'Guarda la preferencia; audio pendiente.',
                        ),
                        secondary: const Icon(Icons.volume_up_rounded),
                        value: settings.soundEnabled,
                        onChanged: settings.setSoundEnabled,
                      ),
                      SwitchListTile(
                        title: const Text('Música'),
                        subtitle: const Text(
                          'Guarda la preferencia; música pendiente.',
                        ),
                        secondary: const Icon(Icons.music_note_rounded),
                        value: settings.musicEnabled,
                        onChanged: settings.setMusicEnabled,
                      ),
                      SwitchListTile(
                        title: const Text('Vibración'),
                        subtitle: const Text('Guarda la preferencia local.'),
                        secondary: const Icon(Icons.vibration_rounded),
                        value: settings.vibrationEnabled,
                        onChanged: settings.setVibrationEnabled,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: spacing.lg),
          PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tutorial', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: spacing.sm),
                const Text('Volvé a ver cómo arrastrar y soltar piezas.'),
                SizedBox(height: spacing.md),
                FilledButton.icon(
                  onPressed: () {
                    context.read<OnboardingProvider>().replayDragOnboarding();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tutorial listo para repetir.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Ver tutorial'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
