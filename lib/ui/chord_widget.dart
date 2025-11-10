import 'package:flutter/material.dart';
import '../models/chord.dart';

class ChordWidget extends StatelessWidget {
  final Chord chord;
  final VoidCallback? onTap;
  final bool showDetails;

  const ChordWidget({
    super.key,
    required this.chord,
    this.onTap,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header s názvem a kategorií
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chord.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        if (showDetails) ...[
                          const SizedBox(height: 4),
                          Text(
                            chord.category,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                    // Modern Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(chord.difficulty),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getDifficultyColor(
                              chord.difficulty,
                            ).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getDifficultyText(chord.difficulty),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Modern Chord diagram
                const SizedBox(height: 20),
                Center(child: _buildChordDiagram()),

                if (showDetails) ...[
                  const SizedBox(height: 16),

                  // Modern Tags
                  if (chord.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chord.tags
                          .map(
                            (tag) => Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Description
                  if (chord.description != null) ...[
                    Text(
                      chord.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChordDiagram() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceVariant,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fret position indicator (vlevo od diagramu)
            if (chord.position >= 1) ...[
              // změněno z > 1 na >= 1
              Container(
                padding: const EdgeInsets.only(top: 40, right: 8),
                child: Text(
                  '${chord.position}fr',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            // Diagram (původní kód)
            Column(
              children: [
                // String names
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: chord.stringNamesList
                      .map(
                        (name) => SizedBox(
                          width: 20,
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 8),

                // Fret lines
                ...List.generate(4, (fretIndex) {
                  final fret = fretIndex + chord.position;
                  return Column(
                    children: [
                      // Fret line
                      Container(
                        height: 1,
                        width: 120,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),

                      // String positions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (stringIndex) {
                          final fingerPosition = chord.getFingerPosition(
                            stringIndex,
                          );
                          return _buildStringPosition(fingerPosition, fret);
                        }),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),

                // Nut (0th fret) - zobrazit jen pokud position = 1
                if (chord.position == 1) ...[
                  Container(
                    height: 2,
                    width: 120,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),

                  // Open strings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (stringIndex) {
                      final fingerPosition = chord.getFingerPosition(
                        stringIndex,
                      );
                      return _buildStringPosition(fingerPosition, 0);
                    }),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStringPosition(int fingerPosition, int fret) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(child: _buildFingerIndicator(fingerPosition, fret)),
    );
  }

  Widget _buildFingerIndicator(int fingerPosition, int fret) {
    return Builder(
      builder: (context) {
        if (fingerPosition == -1) {
          // Muted string
          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 8,
              color: Theme.of(context).colorScheme.onError,
            ),
          );
        } else if (fingerPosition == 0 && fret == 0) {
          // Open string
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green[400],
              shape: BoxShape.circle,
            ),
          );
        } else if (fingerPosition == fret) {
          // Finger position
          return Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${_getFingerNumber(fingerPosition)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else {
          // Empty position
          return const SizedBox.shrink();
        }
      },
    );
  }

  int _getFingerNumber(int position) {
    // Map finger positions to finger numbers
    final fingerMap = <int, int>{
      1: 1, // Index finger
      2: 2, // Middle finger
      3: 3, // Ring finger
      4: 4, // Pinky
    };
    return fingerMap[position] ?? position;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'Začátečník';
      case 'intermediate':
        return 'Střední';
      case 'advanced':
        return 'Pokročilý';
      default:
        return difficulty;
    }
  }
}
