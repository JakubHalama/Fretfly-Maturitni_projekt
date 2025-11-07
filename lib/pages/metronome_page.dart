import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> with SingleTickerProviderStateMixin {
  // Audio players
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _tockPlayer = AudioPlayer();
  
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
      // Načti zvuky z assets
      await _tickPlayer.setAsset('assets/sounds/sound-effect-hd.mp3');
      await _tockPlayer.setAsset('assets/sounds/sound-effect-hd.mp3');

      // Nastavení hlasitosti
      await _tickPlayer.setVolume(1.0);
      await _tockPlayer.setVolume(0.7);
      
      debugPrint('Sounds loaded successfully');
    } catch (e) {
      debugPrint('Error loading sounds: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tickPlayer.dispose();
    _tockPlayer.dispose();
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
    
    // Přehraj tick zvuk
    try {
      if (_currentBeat == 1) {
        // První doba - vyšší zvuk
        await _tickPlayer.seek(Duration.zero);
        _tickPlayer.play();
        HapticFeedback.mediumImpact();
      } else {
        // Ostatní doby - nižší zvuk
        await _tockPlayer.seek(Duration.zero);
        _tockPlayer.play();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronom'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPlaying 
                        ? (_currentBeat == 1 
                            ? Theme.of(context).primaryColor 
                            : Theme.of(context).primaryColor.withOpacity(0.6))
                        : Colors.grey[300],
                    boxShadow: _isPlaying
                        ? [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_bpm',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: _isPlaying ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        Text(
                          'BPM',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: _isPlaying ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (_isPlaying) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_beatsPerBar, (index) {
                    final beatNumber = index + 1;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: beatNumber == _currentBeat
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
              ],
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: () => _changeBpm(-1),
                    icon: const Icon(Icons.remove),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 150,
                    child: Column(
                      children: [
                        Slider(
                          value: _bpm.toDouble(),
                          min: 40,
                          max: 240,
                          divisions: 200,
                          label: '$_bpm BPM',
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton.filled(
                    onPressed: () => _changeBpm(1),
                    icon: const Icon(Icons.add),
                    iconSize: 32,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Column(
                children: [
                  Text(
                    'Takt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimeSignatureButton(2),
                      const SizedBox(width: 12),
                      _buildTimeSignatureButton(3),
                      const SizedBox(width: 12),
                      _buildTimeSignatureButton(4),
                      const SizedBox(width: 12),
                      _buildTimeSignatureButton(6),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: 200,
                height: 60,
                child: FilledButton.icon(
                  onPressed: _startStop,
                  icon: Icon(
                    _isPlaying ? Icons.stop : Icons.play_arrow,
                    size: 32,
                  ),
                  label: Text(
                    _isPlaying ? 'STOP' : 'START',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isPlaying 
                        ? Colors.red 
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              OutlinedButton(
                onPressed: _tapTempo,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: const Text(
                  'TAP TEMPO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Klikej na TAP TEMPO v rytmu pro nastavení BPM',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => _setTimeSignature(beats),
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: Theme.of(context).primaryColor,
        width: 2,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}