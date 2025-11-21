import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fretfly/ui/app_theme.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _detectedNote;
  double _detectedFrequency = 0.0;
  double _deviation = 0.0; // v centech
  String? _selectedString;
  Timer? _analysisTimer;
  String? _recordingPath;
  final List<int> _audioSamples = [];
  static const int sampleRate = 44100;
  static const int bufferSize = 4096; // Velikost bufferu pro analýzu

  // Standardní frekvence strun v Hz
  static const Map<String, double> _stringFrequencies = {
    'E6': 82.41, // 6. struna (nejtlustší)
    'A5': 110.00, // 5. struna
    'D4': 146.83, // 4. struna
    'G3': 196.00, // 3. struna
    'B2': 246.94, // 2. struna
    'E1': 329.63, // 1. struna (nejtenčí)
  };

  // Názvy not pro zobrazení
  static const Map<String, String> _noteNames = {
    'E6': 'E',
    'A5': 'A',
    'D4': 'D',
    'G3': 'G',
    'B2': 'B',
    'E1': 'E',
  };

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Požádej o povolení k mikrofonu
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pro použití ladičky je potřeba povolení k mikrofonu. Zkontrolujte nastavení aplikace.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    try {
      // Zkontroluj, zda má recorder povolení
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nahrávání nemá povolení. Zkontrolujte nastavení mikrofonu v iOS Simulatoru: Device > Microphone > Built-in Microphone',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Získej dočasný soubor pro nahrávání
      final directory = await getTemporaryDirectory();
      _recordingPath =
          '${directory.path}/tuner_recording_${DateTime.now().millisecondsSinceEpoch}.pcm';

      debugPrint('Starting recording to: $_recordingPath');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      debugPrint('Recording started successfully');

      setState(() {
        _isRecording = true;
        _audioSamples.clear();
      });

      // Spusť periodickou analýzu audio souboru
      _analysisTimer = Timer.periodic(const Duration(milliseconds: 200), (
        timer,
      ) {
        _analyzeAudioFile();
      });
    } catch (e) {
      debugPrint('Error starting recorder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chyba při spuštění nahrávání: $e\n\nTip: V iOS Simulatoru nastavte Device > Microphone > Built-in Microphone',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _analysisTimer?.cancel();
    await _recorder.stop();

    // Smaž dočasný soubor
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
    }

    setState(() {
      _isRecording = false;
      _detectedNote = null;
      _detectedFrequency = 0.0;
      _deviation = 0.0;
      _audioSamples.clear();
      _recordingPath = null;
    });
  }

  Future<void> _analyzeAudioFile() async {
    if (_recordingPath == null || !_isRecording) return;

    try {
      final file = File(_recordingPath!);
      if (!await file.exists()) {
        debugPrint('Audio file does not exist yet');
        return;
      }

      final data = await file.readAsBytes();
      if (data.isEmpty) {
        debugPrint('Audio file is empty');
        return;
      }

      debugPrint('Analyzing ${data.length} bytes of audio data');

      // Převod PCM16 dat na seznam int16 hodnot
      final samples = _convertPCM16ToSamples(data);

      if (samples.isEmpty) {
        debugPrint('No samples extracted from audio data');
        return;
      }

      // Použij poslední část dat pro analýzu
      final analysisSamples = samples.length > bufferSize
          ? samples.sublist(samples.length - bufferSize)
          : samples;

      if (analysisSamples.length < 100) {
        debugPrint(
          'Not enough samples for analysis: ${analysisSamples.length}',
        );
        return; // Potřebujeme minimálně nějaká data
      }

      final frequency = _detectFrequency(analysisSamples);
      debugPrint('Detected frequency: $frequency Hz');

      if (frequency > 0) {
        final closestNote = _findClosestNote(frequency);
        double deviation = 0.0;

        if (_selectedString != null) {
          final targetFreq = _stringFrequencies[_selectedString]!;
          deviation = _calculateDeviation(frequency, targetFreq);
          debugPrint(
            'Target: ${targetFreq}Hz, Detected: ${frequency}Hz, Deviation: ${deviation.toStringAsFixed(1)} cents',
          );
        }

        if (mounted) {
          setState(() {
            _detectedFrequency = frequency;
            _detectedNote = closestNote;
            _deviation = deviation;
          });
        }
      } else {
        debugPrint(
          'Frequency detection returned 0 (out of range or no signal)',
        );
      }
    } catch (e) {
      debugPrint('Error analyzing audio: $e');
    }
  }

  List<int> _convertPCM16ToSamples(Uint8List data) {
    final samples = <int>[];
    // PCM16 = 2 byty na vzorek, little-endian
    for (int i = 0; i < data.length - 1; i += 2) {
      final sample = (data[i] | (data[i + 1] << 8));
      // Převod z unsigned na signed (two's complement)
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      samples.add(signedSample);
    }
    return samples;
  }

  double _detectFrequency(List<int> samples) {
    if (samples.length < 2) return 0.0;

    // Zero-crossing detection
    int zeroCrossings = 0;
    for (int i = 1; i < samples.length; i++) {
      // Detekuj průchod nulou
      if ((samples[i - 1] >= 0 && samples[i] < 0) ||
          (samples[i - 1] < 0 && samples[i] >= 0)) {
        zeroCrossings++;
      }
    }

    // Frekvence = počet zero-crossings / 2 / délka v sekundách
    final duration = samples.length / sampleRate;
    final frequency = (zeroCrossings / 2) / duration;

    // Filtruj nereálné frekvence (pro kytaru: 50-500 Hz)
    if (frequency < 50 || frequency > 500) {
      return 0.0;
    }

    return frequency;
  }

  String _findClosestNote(double frequency) {
    String closestKey = '';
    double minDiff = double.infinity;

    for (final entry in _stringFrequencies.entries) {
      final diff = (frequency - entry.value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestKey = entry.key;
      }
    }

    return _noteNames[closestKey] ?? '';
  }

  double _calculateDeviation(double detectedFreq, double targetFreq) {
    if (detectedFreq <= 0 || targetFreq <= 0) return 0.0;
    // Vypočítej odchylku v centech (1 cent = 1/100 půltónu)
    final cents = 1200 * (log(detectedFreq / targetFreq) / log(2));
    return cents;
  }

  Color _getDeviationColor() {
    final absDeviation = _deviation.abs();
    if (absDeviation < 5) {
      return Colors.green; // Správně naladěno
    } else if (absDeviation < 20) {
      return Colors.orange; // Blízko
    } else {
      return Colors.red; // Daleko
    }
  }

  String _getDeviationText() {
    final absDeviation = _deviation.abs();
    if (absDeviation < 5) {
      return 'Správně';
    } else if (_deviation > 0) {
      return 'Vysoká';
    } else {
      return 'Nízká';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hlavní indikátor
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: _isRecording
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryBrand,
                          AppTheme.secondaryBrand,
                        ],
                      )
                    : null,
                color: _isRecording
                    ? null
                    : Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isRecording
                        ? AppTheme.primaryBrand.withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic_rounded : Icons.tune_rounded,
                size: 80,
                color: _isRecording
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Detekovaný tón a frekvence
            if (_isRecording &&
                _detectedNote != null &&
                _detectedFrequency > 0) ...[
              Text(
                _detectedNote!,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_detectedFrequency.toStringAsFixed(1)} Hz',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ] else if (_isRecording) ...[
              Text(
                'Poslouchejte...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Text(
                _selectedString != null
                    ? 'Vyberte strunu a začněte ladit'
                    : 'Vyberte strunu a začněte ladit',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Použij ladičku k přesnému naladění kytary',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Vizuální indikátor ladění - zobrazit když je vybraná struna
            if (_selectedString != null) ...[
              _buildTuningIndicator(context),
              const SizedBox(height: 16),
            ],

            // Indikátor odchylky - zobrazit pouze když je detekovaná frekvence
            if (_isRecording && _detectedFrequency > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getDeviationColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getDeviationColor(), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _deviation.abs() < 5 ? Icons.check_circle : Icons.tune,
                      color: _getDeviationColor(),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getDeviationText(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _getDeviationColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_deviation.abs() >= 5) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${_deviation > 0 ? '+' : ''}${_deviation.toStringAsFixed(1)} centů',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getDeviationColor(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Textová instrukce
              if (_deviation.abs() >= 5) ...[
                const SizedBox(height: 12),
                Text(
                  _deviation > 0
                      ? 'Ladit níž (uvolnit strunu)'
                      : 'Ladit výš (napnout strunu)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getDeviationColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 48),

            // Výběr strun
            Container(
              padding: const EdgeInsets.all(28),
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
                    'Standardní ladění',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTuningNote(context, 'E6', 'E', '6. struna'),
                        const SizedBox(width: 12),
                        _buildTuningNote(context, 'A5', 'A', '5. struna'),
                        const SizedBox(width: 12),
                        _buildTuningNote(context, 'D4', 'D', '4. struna'),
                        const SizedBox(width: 12),
                        _buildTuningNote(context, 'G3', 'G', '3. struna'),
                        const SizedBox(width: 12),
                        _buildTuningNote(context, 'B2', 'B', '2. struna'),
                        const SizedBox(width: 12),
                        _buildTuningNote(context, 'E1', 'E', '1. struna'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tlačítko start/stop
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: _isRecording
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                    const SizedBox(width: 12),
                    Text(
                      _isRecording ? 'Zastavit' : 'Začít ladit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildTuningIndicator(BuildContext context) {
    if (_selectedString == null) return const SizedBox.shrink();

    final hasDetection = _detectedFrequency > 0 && _isRecording;
    final absDeviation = _deviation.abs();

    // Normalizuj odchylku pro zobrazení (-50 až +50 centů = -1.0 až +1.0)
    // Pokud není detekce, použij 0 (uprostřed)
    final normalizedDeviation = hasDetection
        ? (_deviation.clamp(-50.0, 50.0) / 50.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Šipka nahoru
          Icon(
            Icons.arrow_upward_rounded,
            size: 32,
            color: hasDetection && _deviation < -5
                ? Colors.red
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),

          // Posuvník/indikátor
          LayoutBuilder(
            builder: (context, constraints) {
              final sliderWidth = constraints.maxWidth;
              final centerX = sliderWidth / 2;
              final indicatorPosition =
                  centerX + (normalizedDeviation * (sliderWidth / 2 - 20));

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pozadí posuvníku
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Zelená střední zóna (správně naladěno)
                  Container(
                    width: 60,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasDetection && absDeviation < 5
                          ? Colors.green
                          : Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Indikátor pozice
                  Positioned(
                    left: indicatorPosition.clamp(8.0, sliderWidth - 8.0) - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: hasDetection
                            ? _getDeviationColor()
                            : Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (hasDetection
                                        ? _getDeviationColor()
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant)
                                    .withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Šipka dolů
          Icon(
            Icons.arrow_downward_rounded,
            size: 32,
            color: hasDetection && _deviation > 5
                ? Colors.red
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 12),

          // Textová instrukce
          if (!hasDetection)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Začněte ladit pro zobrazení',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else if (absDeviation >= 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _deviation > 0
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 20,
                  color: _getDeviationColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  _deviation > 0 ? 'Uvolnit strunu' : 'Napnout strunu',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getDeviationColor(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Správně naladěno',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTuningNote(
    BuildContext context,
    String stringKey,
    String note,
    String string,
  ) {
    final isSelected = _selectedString == stringKey;
    final targetFreq = _stringFrequencies[stringKey]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedString = stringKey;
        });
        HapticFeedback.selectionClick();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryBrand, AppTheme.secondaryBrand],
                    )
                  : null,
              color: isSelected
                  ? null
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBrand.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${targetFreq.toStringAsFixed(1)} Hz',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white70
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            string,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
