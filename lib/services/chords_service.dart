import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chord.dart';

class ChordsService {
  static final ChordsService _instance = ChordsService._internal();
  factory ChordsService() => _instance;
  ChordsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'chords';

  // Načte všechny akordy
  Stream<List<Chord>> getAllChords() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Chord.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Načte akordy podle kategorie
  Stream<List<Chord>> getChordsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Chord.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Načte akordy podle obtížnosti
  Stream<List<Chord>> getChordsByDifficulty(String difficulty) {
    return _firestore
        .collection(_collection)
        .where('difficulty', isEqualTo: difficulty)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Chord.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Vyhledá akordy podle názvu
  Stream<List<Chord>> searchChords(String query) {
    if (query.isEmpty) return getAllChords();

    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Chord.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Načte konkrétní akord
  Future<Chord?> getChord(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Chord.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting chord: $e');
      return null;
    }
  }

  // Přidá nový akord
  Future<String?> addChord(Chord chord) async {
    try {
      final docRef = _firestore.collection(_collection).doc(chord.id);
      await docRef.set(chord.toMap(), SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      print('Error adding chord: $e');
      return null;
    }
  }

  // Aktualizuje akord
  Future<bool> updateChord(String id, Chord chord) async {
    try {
      await _firestore.collection(_collection).doc(id).update(chord.toMap());
      return true;
    } catch (e) {
      print('Error updating chord: $e');
      return false;
    }
  }

  // Smaže akord
  Future<bool> deleteChord(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting chord: $e');
      return false;
    }
  }

  // Načte všechny kategorie
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final categories = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category']);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Inicializuje databázi s základními akordy
  // Inicializuje databázi s základními akordy
  Future<void> initializeChords() async {
    final chords = [
      // Major akordy (všechny tóny)
      Chord(
        id: 'c_major',
        name: 'C',
        category: 'Major',
        fingering: [0, 1, 0, 2, 1, 0],
        position: 1,
        tags: ['major', 'open', 'beginner'],
        difficulty: 'beginner',
        description: 'Základní C dur akord',
      ),
      Chord(
        id: 'csharp_major',
        name: 'C#',
        category: 'Major',
        fingering: [4, 4, 6, 6, 6, 4],
        position: 4,
        hasBarre: true,
        barreFret: 4,
        tags: ['major', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'C# dur s barre na čtvrtém pražci',
      ),
      Chord(
        id: 'd_major',
        name: 'D',
        category: 'Major',
        fingering: [-1, 0, 0, 2, 3, 2],
        position: 1,
        tags: ['major', 'open', 'beginner'],
        difficulty: 'beginner',
        description: 'Základní D dur akord',
      ),
      Chord(
        id: 'dsharp_major',
        name: 'D#',
        category: 'Major',
        fingering: [6, 6, 8, 8, 8, 6],
        position: 6,
        hasBarre: true,
        barreFret: 6,
        tags: ['major', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'D# dur s barre na šestém pražci',
      ),
      Chord(
        id: 'e_major',
        name: 'E',
        category: 'Major',
        fingering: [0, 2, 2, 1, 0, 0],
        position: 1,
        tags: ['major', 'open', 'beginner'],
        difficulty: 'beginner',
        description: 'Základní E dur akord',
      ),
      Chord(
        id: 'f_major',
        name: 'F',
        category: 'Major',
        fingering: [1, 3, 3, 2, 1, 1],
        position: 1,
        hasBarre: true,
        barreFret: 1,
        tags: ['major', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'F dur s barre na prvním pražci',
      ),
      Chord(
        id: 'fsharp_major',
        name: 'F#',
        category: 'Major',
        fingering: [2, 4, 4, 3, 2, 2],
        position: 2,
        hasBarre: true,
        barreFret: 2,
        tags: ['major', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'F# dur s barre na druhém pražci',
      ),
      Chord(
        id: 'g_major',
        name: 'G',
        category: 'Major',
        fingering: [3, 2, 0, 0, 3, 3],
        position: 1,
        tags: ['major', 'open', 'beginner'],
        difficulty: 'beginner',
        description: 'Základní G dur akord',
      ),
      Chord(
        id: 'gsharp_major',
        name: 'G#',
        category: 'Major',
        fingering: [4, 6, 6, 5, 4, 4],
        position: 4,
        hasBarre: true,
        barreFret: 4,
        tags: ['major', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'G# dur s barre na čtvrtém pražci',
      ),
      Chord(
        id: 'a_major',
        name: 'A',
        category: 'Major',
        fingering: [0, 0, 2, 2, 2, 0],
        position: 1,
        tags: ['major', 'open', 'beginner'],
        difficulty: 'beginner',
        description: 'Základní A dur akord',
      ),
      Chord(
        id: 'asharp_major',
        name: 'A#',
        category: 'Major',
        fingering: [1, 1, 3, 3, 3, 1],
        position: 1,
        hasBarre: true,
        barreFret: 1,
        tags: ['major', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'A# dur s barre na prvním pražci',
      ),
      Chord(
        id: 'b_major',
        name: 'B',
        category: 'Major',
        fingering: [2, 2, 4, 4, 4, 2],
        position: 2,
        hasBarre: true,
        barreFret: 2,
        tags: ['major', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'B dur s barre na druhém pražci',
      ),

      // Minor akordy (všechny tóny)
      Chord(
        id: 'c_minor',
        name: 'Cm',
        category: 'Minor',
        fingering: [3, 3, 5, 5, 4, 3],
        position: 3,
        hasBarre: true,
        barreFret: 3,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'C moll s barre na třetím pražci',
      ),
      Chord(
        id: 'csharp_minor',
        name: 'C#m',
        category: 'Minor',
        fingering: [4, 4, 6, 6, 5, 4],
        position: 4,
        hasBarre: true,
        barreFret: 4,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'C# moll s barre na čtvrtém pražci',
      ),
      Chord(
        id: 'd_minor',
        name: 'Dm',
        category: 'Minor',
        fingering: [-1, 0, 0, 2, 3, 1],
        position: 1,
        tags: ['minor', 'open', 'beginner'],
        difficulty: 'beginner',
        description: 'Základní D moll akord',
      ),
      Chord(
        id: 'dsharp_minor',
        name: 'D#m',
        category: 'Minor',
        fingering: [6, 6, 8, 8, 7, 6],
        position: 6,
        hasBarre: true,
        barreFret: 6,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'D# moll s barre na šestém pražci',
      ),
      Chord(
        id: 'e_minor',
        name: 'Em',
        category: 'Minor',
        fingering: [0, 2, 2, 0, 0, 0],
        position: 1,
        tags: ['minor', 'open', 'beginner'],
        difficulty: 'beginner',
        description: 'Základní E moll akord',
      ),
      Chord(
        id: 'f_minor',
        name: 'Fm',
        category: 'Minor',
        fingering: [1, 3, 3, 1, 1, 1],
        position: 1,
        hasBarre: true,
        barreFret: 1,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'F moll s barre na prvním pražci',
      ),
      Chord(
        id: 'fsharp_minor',
        name: 'F#m',
        category: 'Minor',
        fingering: [2, 4, 4, 2, 2, 2],
        position: 2,
        hasBarre: true,
        barreFret: 2,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'F# moll s barre na druhém pražci',
      ),
      Chord(
        id: 'g_minor',
        name: 'Gm',
        category: 'Minor',
        fingering: [3, 5, 5, 3, 3, 3],
        position: 3,
        hasBarre: true,
        barreFret: 3,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'G moll s barre na třetím pražci',
      ),
      Chord(
        id: 'gsharp_minor',
        name: 'G#m',
        category: 'Minor',
        fingering: [4, 6, 6, 4, 4, 4],
        position: 4,
        hasBarre: true,
        barreFret: 4,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'G# moll s barre na čtvrtém pražci',
      ),
      Chord(
        id: 'a_minor',
        name: 'Am',
        category: 'Minor',
        fingering: [0, 1, 2, 2, 1, 0],
        position: 1,
        tags: ['minor', 'open', 'beginner'],
        difficulty: 'beginner',
        description: 'Základní A moll akord',
      ),
      Chord(
        id: 'asharp_minor',
        name: 'A#m',
        category: 'Minor',
        fingering: [1, 3, 3, 1, 1, 1],
        position: 1,
        hasBarre: true,
        barreFret: 1,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'A# moll s barre na prvním pražci',
      ),
      Chord(
        id: 'b_minor',
        name: 'Bm',
        category: 'Minor',
        fingering: [2, 2, 4, 4, 3, 2],
        position: 2,
        hasBarre: true,
        barreFret: 2,
        tags: ['minor', 'barre', 'intermediate'],
        difficulty: 'intermediate',
        description: 'B moll s barre na druhém pražci',
      ),

      // Seventh akordy
      Chord(
        id: 'c_major7',
        name: 'Cmaj7',
        category: 'Seventh',
        fingering: [0, 3, 2, 0, 1, 0],
        position: 1,
        tags: ['major7', 'open', 'intermediate'],
        difficulty: 'intermediate',
        description: 'C dur septakord',
      ),
      Chord(
        id: 'a_minor7',
        name: 'Am7',
        category: 'Seventh',
        fingering: [0, 0, 2, 0, 1, 0],
        position: 1,
        tags: ['minor7', 'open', 'intermediate'],
        difficulty: 'intermediate',
        description: 'A moll septakord',
      ),
    ];

    for (final chord in chords) {
      final docRef = _firestore.collection(_collection).doc(chord.id);
      final existing = await docRef.get();
      if (!existing.exists) {
        await docRef.set(chord.toMap());
      }
    }
  }
}
