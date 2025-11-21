import 'package:flutter/material.dart';
import 'package:fretfly/ui/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBrand,
              AppTheme.secondaryBrand,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo s animací
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            children: [
                              // Ikona kytary nebo hudební nota
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Název aplikace s různými styly
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Fret',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900, // Extra tučné
                                        color: Colors.white,
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 4),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'fly',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w500, // Medium - trochu tenčí
                                        color: Colors.white,
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 4),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Podtitulek
                              Text(
                                'Tvůj kytarový pomocník',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Loading indikátor
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Version info dole
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}