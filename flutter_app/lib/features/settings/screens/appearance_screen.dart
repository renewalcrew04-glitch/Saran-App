import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Choose how Saran looks to you',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ThemeCard(
                      mode: ThemeMode.light,
                      label: 'Light',
                      icon: Icons.light_mode_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      previewBg: const Color(0xFFF8FAFC),
                      previewAccent: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemeCard(
                      mode: ThemeMode.dark,
                      label: 'Dark',
                      icon: Icons.dark_mode_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      previewBg: const Color(0xFF0F172A),
                      previewAccent: const Color(0xFF818CF8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemeCard(
                      mode: ThemeMode.system,
                      label: 'System',
                      icon: Icons.brightness_auto_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                      previewBg: null, // split preview
                      previewAccent: const Color(0xFFF97316),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'System mode automatically switches between light and dark based on your device settings.',
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final ThemeMode mode;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? previewBg;
  final Color previewAccent;

  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.previewBg,
    required this.previewAccent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? previewAccent : scheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: previewAccent.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Mini phone preview
              Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: mode == ThemeMode.system
                      ? const LinearGradient(
                          colors: [Color(0xFFF8FAFC), Color(0xFF0F172A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: mode == ThemeMode.system ? null : previewBg,
                ),
                child: Center(
                  child: Icon(icon, size: 28, color: previewAccent),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? previewAccent : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? previewAccent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? previewAccent : scheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
