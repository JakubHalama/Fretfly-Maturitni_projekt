import 'package:flutter/material.dart';
import '../models/chord.dart';
import '../services/chords_service.dart';
import '../ui/chord_widget.dart';

class ChordsPage extends StatefulWidget {
  const ChordsPage({super.key});

  @override
  State<ChordsPage> createState() => _ChordsPageState();
}

class _ChordsPageState extends State<ChordsPage> {
  final ChordsService _chordsService = ChordsService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedRoot = 'All';
  bool _isInitialized = false;
  final List<String> _tones = [
    'All',
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      // Inicializuj databázi s akordy (pouze jednou)
      await _chordsService.initializeChords();

      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Chord>> _getChordsStream() {
    if (_searchController.text.isNotEmpty) {
      return _chordsService.searchChords(_searchController.text);
    } else {
      return _chordsService.getAllChords();
    }
  }

  List<Chord> _applyFilters(List<Chord> chords) {
    var filtered = chords;

    if (_selectedRoot != 'All') {
      filtered = filtered
          .where((chord) => chord.root == _selectedRoot)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akordy'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isInitialized = false;
                _selectedRoot = 'All';
              });
              _initializeData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Hledat akordy...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Tone filter only
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tones
                    .map(
                      (tone) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tone),
                          selected: _selectedRoot == tone,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRoot = tone;
                            });
                          },
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                          checkmarkColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // Chords list
          Expanded(
            child: StreamBuilder<List<Chord>>(
              stream: _getChordsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chyba při načítání akordů',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isInitialized = false;
                            });
                            _initializeData();
                          },
                          child: const Text('Zkusit znovu'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.music_note,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Žádné akordy nenalezeny',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Zkuste změnit filtry nebo vyhledávání',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                final chords = _applyFilters(snapshot.data!);

                return ListView.builder(
                  itemCount: chords.length,
                  itemBuilder: (context, index) {
                    final chord = chords[index];
                    return ChordWidget(
                      chord: chord,
                      onTap: () => _showChordDetail(chord),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showChordDetail(Chord chord) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ChordWidget(chord: chord, showDetails: true),
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