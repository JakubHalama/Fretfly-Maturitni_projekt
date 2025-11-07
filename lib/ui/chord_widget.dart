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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (showDetails) ...[
                        const SizedBox(height: 4),
                        Text(
                          chord.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(chord.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficultyText(chord.difficulty),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Chord diagram
              Center(
                child: _buildChordDiagram(),
              ),
              
              if (showDetails) ...[
                const SizedBox(height: 16),
                
                // Tags
                if (chord.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: chord.tags.map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.grey[200],
                      labelStyle: const TextStyle(fontSize: 12),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Description
                if (chord.description != null) ...[
                  Text(
                    chord.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChordDiagram() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fret position indicator (vlevo od diagramu)
          if (chord.position >= 1) ...[  // změněno z > 1 na >= 1
            Container(
              padding: const EdgeInsets.only(top: 40, right: 8),
              child: Text(
                '${chord.position}fr',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
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
                children: chord.stringNamesList.map((name) => 
                  SizedBox(
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
                ).toList(),
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
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    
                    // String positions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (stringIndex) {
                        final fingerPosition = chord.getFingerPosition(stringIndex);
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
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                
                // Open strings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (stringIndex) {
                    final fingerPosition = chord.getFingerPosition(stringIndex);
                    return _buildStringPosition(fingerPosition, 0);
                  }),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStringPosition(int fingerPosition, int fret) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: _buildFingerIndicator(fingerPosition, fret),
      ),
    );
  }

  Widget _buildFingerIndicator(int fingerPosition, int fret) {
    if (fingerPosition == -1) {
      // Muted string
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.red[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          size: 8,
          color: Colors.white,
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
            style: const TextStyle(
              color: Colors.white,
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