import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fretfly/services/theme_service.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vzhled'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motiv',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            
            _buildThemeOption(
              context: context,
              themeService: themeService,
              title: 'Světlý',
              subtitle: 'Vždy světlý motiv',
              icon: Icons.light_mode_rounded,
              value: 'light',
              color: const Color(0xFFFF9500),
            ),
            const SizedBox(height: 12),
            
            _buildThemeOption(
              context: context,
              themeService: themeService,
              title: 'Tmavý',
              subtitle: 'Vždy tmavý motiv',
              icon: Icons.dark_mode_rounded,
              value: 'dark',
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 12),
            
            _buildThemeOption(
              context: context,
              themeService: themeService,
              title: 'Systémový',
              subtitle: 'Podle nastavení zařízení',
              icon: Icons.brightness_auto_rounded,
              value: 'system',
              color: const Color(0xFF4A90E2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeService themeService,
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final isSelected = themeService.getThemeModeString() == value;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          ThemeMode mode;
          switch (value) {
            case 'light':
              mode = ThemeMode.light;
              break;
            case 'dark':
              mode = ThemeMode.dark;
              break;
            case 'system':
            default:
              mode = ThemeMode.system;
              break;
          }
          await themeService.setThemeMode(mode);
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Motiv změněn na: $title'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.1)
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? color
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}