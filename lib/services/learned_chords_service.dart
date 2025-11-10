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
    } else {
      await ref.delete();
    }
  }

  Future<bool> isLearned(String chordId) async {
    final doc = await _collectionRef().doc(chordId).get();
    return doc.exists;
  }
}


