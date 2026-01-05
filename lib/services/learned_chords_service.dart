import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chord.dart';

class LearnedChordsService {
  static final LearnedChordsService _instance = LearnedChordsService._internal();
  factory LearnedChordsService() => _instance;
  LearnedChordsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _collectionRef() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('User not logged in');
    }
    return _firestore.collection('users').doc(uid).collection('learned_chords');
  }

  Stream<Set<String>> learnedChordIds() {
    final uid = _uid;
    if (uid == null) return const Stream<Set<String>>.empty();
    return _collectionRef().snapshots().map((snapshot) {
      return snapshot.docs.map((d) => d.id).toSet();
    });
  }

  Stream<int> learnedCount() {
    return learnedChordIds().map((ids) => ids.length);
  }

  Stream<List<Map<String, dynamic>>> learnedChords() {
    final uid = _uid;
    if (uid == null) return const Stream<List<Map<String, dynamic>>>.empty();
    return _collectionRef()
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> setLearned(Chord chord, {required bool learned}) async {
    final ref = _collectionRef().doc(chord.id);
    if (learned) {
      await ref.set({
        'name': chord.name,
        'category': chord.category,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Zkontroluj, jestli uživatel nemá naučené všechny akordy
      final allChordsSnapshot =
          await _firestore.collection('chords').get(const GetOptions(source: Source.serverAndCache));
      final learnedSnapshot = await _collectionRef().get();

      final totalChords = allChordsSnapshot.docs.length;
      final learnedCount = learnedSnapshot.docs.length;

      if (totalChords > 0 && learnedCount >= totalChords) {
        final userDoc =
            _firestore.collection('users').doc(_uid);
        final achievementsRef = userDoc.collection('achievements');

        await achievementsRef.doc('maestro').set({
          'title': 'Maestro',
          'description': 'Naučil ses všechny akordy v knihovně.',
          'icon': '🎓',
          'unlockedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Další ocenění: první naučený akord
      if (learnedSnapshot.docs.isEmpty) {
        final userDoc =
            _firestore.collection('users').doc(_uid);
        final achievementsRef = userDoc.collection('achievements');

        await achievementsRef.doc('prvni_akord').set({
          'title': 'První akord',
          'description': 'Označil jsi svůj první naučený akord.',
          'icon': '🎵',
          'unlockedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } else {
      await ref.delete();
    }
  }

  Future<bool> isLearned(String chordId) async {
    final doc = await _collectionRef().doc(chordId).get();
    return doc.exists;
  }
}


