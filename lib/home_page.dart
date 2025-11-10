import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fretfly/auth_service.dart';
import 'package:fretfly/login_page.dart';
import 'package:fretfly/pages/metronome_page.dart';
import 'package:fretfly/pages/tuner_page.dart';
import 'package:fretfly/pages/chords_page.dart';
import 'package:fretfly/pages/profile_page.dart';
import 'package:fretfly/ui/app_theme.dart';
import 'package:fretfly/services/learned_chords_service.dart';
import 'package:fretfly/services/streak_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 2; // center Home
  late final List<Map<String, String>> _tips;
  late final int _tipIndex;

  @override
  void initState() {
    super.initState();
    // Update streak on app start if already signed in
    StreakService().updateOnLogin();
    _tips = [
      {
        'title': 'Cvič pomalu a přesně',
        'body': 'Rychlost přijde s přesností. Začni na 60 BPM a postupně zrychluj!',
      },
      {
        'title': 'Pravidelnost je klíč',
        'body': 'Raději 15 minut denně než 2 hodiny jednou týdně. Vytvoř si návyk.',
      },
      {
        'title': 'Metronom je tvůj kamarád',
        'body': 'Začni pomalu a teprve po zvládnutí rytmu zvyšuj BPM po 5.',
      },
      {
        'title': 'Správné držení ruky',
        'body': 'Prsty drž kolmo k hmatníku a hraj co nejblíže u pražce pro čistý tón.',
      },
      {
        'title': 'Tlumení strun',
        'body': 'Využívej pravou i levou ruku k tlumení nežádoucích strun pro čistý zvuk.',
      },
      {
        'title': 'Opakuj obtížné úseky',
        'body': 'Zaměř se na 1–2 problematické takty a trénuj je v krátkých smyčkách.',
      },
      {
        'title': 'Trénuj výměny akordů',
        'body': 'Vyber dvojici akordů a procvičuj plynulé přechody 2–3 minuty denně.',
      },
    ];
    _tipIndex = Random().nextInt(_tips.length);
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return const MetronomePage();
      case 1:
        return const TunerPage();
      case 2:
        return _buildHomePage();
      case 3:
        return const ChordsPage();
      case 4:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Hero Section with Brand Gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryBrand, AppTheme.secondaryBrand],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ahoj! 👋',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pojďme hrát!',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => _logout(context),
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: 'Odhlásit se',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Modern Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<int>(
                            stream: LearnedChordsService().learnedCount(),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return _buildStatCard(
                                icon: Icons.music_note_rounded,
                                label: 'Naučených akordů',
                                value: '$count',
                                color: Theme.of(context).colorScheme.onPrimary,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StreamBuilder<int>(
                            stream: StreakService().currentStreakStream(),
                            builder: (context, snapshot) {
                              final streak = snapshot.data ?? 0;
                              return _buildStatCard(
                                icon: Icons.local_fire_department_rounded,
                                label: 'Dní v řadě',
                                value: '$streak',
                                color: Theme.of(context).colorScheme.onPrimary,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Quick Actions Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rychlé akce',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.access_time_filled_rounded,
                        title: 'Metronom',
                        subtitle: 'Procvič rytmus',
                        color: AppTheme.primary,
                        onTap: () => setState(() => _tabIndex = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.tune_rounded,
                        title: 'Ladička',
                        subtitle: 'Nalaď kytaru',
                        color: AppTheme.secondary,
                        onTap: () => setState(() => _tabIndex = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickActionCard(
                  context,
                  icon: Icons.grid_view_rounded,
                  title: 'Knihovna akordů',
                  subtitle: 'Nauč se nové akordy',
                  color: AppTheme.tertiaryBrand,
                  onTap: () => setState(() => _tabIndex = 3),
                  fullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Practice Tip - Modern Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip dne',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryBrand, AppTheme.secondaryBrand],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBrand.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tips[_tipIndex]['title'] ?? '',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _tips[_tipIndex]['body'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isOnPrimary = color == Colors.white || color == Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isOnPrimary
            ? Colors.white.withOpacity(0.2)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: isOnPrimary
            ? Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isOnPrimary ? 0.1 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOnPrimary
                  ? Colors.white.withOpacity(0.3)
                  : AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isOnPrimary
                  ? Colors.white
                  : AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isOnPrimary
                  ? Colors.white
                  : AppTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isOnPrimary
                  ? Colors.white.withOpacity(0.9)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: fullWidth
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color,
                            color.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: color,
                      size: 20,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color,
                            color.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _titleForIndex(int i) {
    switch (i) {
      case 0:
        return 'Metronom';
      case 1:
        return 'Ladička';
      case 2:
        return 'Fretfly';
      case 3:
        return 'Akordy';
      case 4:
        return 'Profil';
      default:
        return 'Fretfly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: _tabIndex == 2 ? null : AppBar(
        title: Text(_titleForIndex(_tabIndex)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBody(),
          // Modern floating pill nav bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 20 + bottomPadding,
            child: _FloatingPillNavBar(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
              items: const [
                _NavItem(
                  icon: Icons.access_time_outlined,
                  selectedIcon: Icons.access_time_filled_rounded,
                  label: 'Metro',
                ),
                _NavItem(
                  icon: Icons.tune_outlined,
                  selectedIcon: Icons.tune_rounded,
                  label: 'Tuner',
                ),
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _NavItem(
                  icon: Icons.grid_view_outlined,
                  selectedIcon: Icons.grid_view_rounded,
                  label: 'Chords',
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingPillNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int index) onTap;
  final List<_NavItem> items;
  const _FloatingPillNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrand.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < items.length; i++)
                  _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onPressed: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onPressed;
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    key: ValueKey(selected),
                    size: 24,
                    color: selected
                        ? AppTheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}