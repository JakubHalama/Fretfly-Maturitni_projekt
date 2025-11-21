import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fretfly/ui/app_theme.dart';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> with SingleTickerProviderStateMixin {
  // Audio players
  final AudioPlayer _accentPlayer = AudioPlayer(); // Pro první dobu (vyšší pitch)
  final AudioPlayer _regularPlayer = AudioPlayer(); // Pro ostatní doby (normální)
  
  // Metronome state
  bool _isPlaying = false;
  int _bpm = 120;
  int _beatsPerBar = 4;
  int _currentBeat = 0;
  Timer? _timer;
  
  // Tap tempo
  final List<DateTime> _tapTimes = [];
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadSounds();
  }

  Future<void> _loadSounds() async {
    try {
      // Načti stejný zvuk pro oba playery
      await _accentPlayer.setAsset('assets/sounds/sound-effect-hd.mp3');
      await _regularPlayer.setAsset('assets/sounds/sound-effect-hd.mp3');

      // První doba: vyšší pitch (rychlejší přehrávání = vyšší tón)
      await _accentPlayer.setVolume(1.0);
      await _accentPlayer.setSpeed(2.0); // Vyšší pitch
      
      // Ostatní doby: normální pitch
      await _regularPlayer.setVolume(0.7);
      await _regularPlayer.setSpeed(1.0); // Normální pitch
      
      debugPrint('Sounds loaded successfully');
    } catch (e) {
      debugPrint('Error loading sounds: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accentPlayer.dispose();
    _regularPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startStop() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _currentBeat = 0;
        _startMetronome();
      } else {
        _stopMetronome();
      }
    });
  }

  void _startMetronome() {
    _playBeat();
    final interval = Duration(milliseconds: (60000 / _bpm).round());
    _timer = Timer.periodic(interval, (timer) {
      _playBeat();
    });
  }

  void _stopMetronome() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _currentBeat = 0;
    });
  }

  Future<void> _playBeat() async {
    setState(() {
      _currentBeat = (_currentBeat % _beatsPerBar) + 1;
    });
    
    // Animace
    _animationController.forward(from: 0.0);
    
    // Přehraj správný zvuk podle doby
    try {
      if (_currentBeat == 1) {
        // PRVNÍ DOBA - vyšší pitch (speed 2.0)
        await _accentPlayer.seek(Duration.zero);
        _accentPlayer.play();
        HapticFeedback.mediumImpact();
      } else {
        // OSTATNÍ DOBY - normální pitch (speed 1.0)
        await _regularPlayer.seek(Duration.zero);
        _regularPlayer.play();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Playback error: $e');
      HapticFeedback.lightImpact();
    }
  }

  void _changeBpm(int delta) {
    setState(() {
      _bpm = (_bpm + delta).clamp(40, 240);
      if (_isPlaying) {
        _stopMetronome();
        _startMetronome();
      }
    });
  }

  void _setTimeSignature(int beats) {
    setState(() {
      _beatsPerBar = beats;
      _currentBeat = 0;
    });
  }

  void _tapTempo() {
    final now = DateTime.now();
    _tapTimes.add(now);
    
    if (_tapTimes.length > 4) {
      _tapTimes.removeAt(0);
    }
    
    if (_tapTimes.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < _tapTimes.length; i++) {
        intervals.add(_tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds);
      }
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final newBpm = (60000 / avgInterval).round().clamp(40, 240);
      
      setState(() {
        _bpm = newBpm;
        if (_isPlaying) {
          _stopMetronome();
          _startMetronome();
        }
      });
    }
    
    HapticFeedback.mediumImpact();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (_tapTimes.isNotEmpty && 
          DateTime.now().difference(_tapTimes.last).inSeconds > 2) {
        _tapTimes.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(), // Zabraňuje bounce efektu
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom - 
                    64, // Výška paddingu
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isPlaying 
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _currentBeat == 1
                              ? [AppTheme.primaryBrand, AppTheme.secondaryBrand]
                              : [
                                  AppTheme.primaryBrand.withOpacity(0.7),
                                  AppTheme.secondaryBrand.withOpacity(0.5),
                                ],
                        )
                      : null,
                  color: _isPlaying ? null : AppTheme.surfaceVariant,
                  boxShadow: _isPlaying
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBrand.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_bpm',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w700,
                          color: _isPlaying 
                              ? Colors.white 
                              : AppTheme.mutedText,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BPM',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _isPlaying 
                              ? Colors.white.withOpacity(0.9)
                              : AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_isPlaying) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_beatsPerBar, (index) {
                  final beatNumber = index + 1;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: beatNumber == _currentBeat ? 14 : 10,
                    height: beatNumber == _currentBeat ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: beatNumber == _currentBeat
                          ? AppTheme.primary
                          : AppTheme.surfaceVariant,
                      boxShadow: beatNumber == _currentBeat
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBrand.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
            ] else ...[
              const SizedBox(height: 32),
            ],
            
            // BPM Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        onPressed: () => _changeBpm(-1),
                        icon: const Icon(Icons.remove_rounded),
                        iconSize: 24,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.surfaceVariant,
                          foregroundColor: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Slider(
                              value: _bpm.toDouble(),
                              min: 40,
                              max: 240,
                              divisions: 200,
                              label: '$_bpm BPM',
                              activeColor: AppTheme.primary,
                              onChanged: (value) {
                                setState(() {
                                  _bpm = value.round();
                                  if (_isPlaying) {
                                    _stopMetronome();
                                    _startMetronome();
                                  }
                                });
                              },
                            ),
                            Text(
                              '$_bpm BPM',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () => _changeBpm(1),
                        icon: const Icon(Icons.add_rounded),
                        iconSize: 24,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.surfaceVariant,
                          foregroundColor: AppTheme.primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Time Signature
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Takt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryText,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeSignatureButton(2),
                        const SizedBox(width: 8),
                        _buildTimeSignatureButton(3),
                        const SizedBox(width: 8),
                        _buildTimeSignatureButton(4),
                        const SizedBox(width: 8),
                        _buildTimeSignatureButton(6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Main Control Button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton.icon(
                onPressed: _startStop,
                icon: Icon(
                  _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 28,
                ),
                label: Text(
                  _isPlaying ? 'STOP' : 'START',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _isPlaying 
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _tapTempo,
                icon: const Icon(Icons.touch_app_rounded),
                label: const Text(
                  'TAP TEMPO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Klikej na TAP TEMPO v rytmu pro nastavení BPM',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSignatureButton(int beats) {
    final isSelected = _beatsPerBar == beats;
    return FilterChip(
      label: Text(
        '$beats/4',
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected 
              ? Colors.white 
              : AppTheme.primary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => _setTimeSignature(beats),
      selectedColor: AppTheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: AppTheme.primary,
        width: 2,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }
}