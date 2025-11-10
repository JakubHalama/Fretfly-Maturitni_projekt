import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? _userDoc() {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  /// Call this after a successful login or on app start when user is already signed in.
  Future<void> updateOnLogin() async {
    final userRef = _userDoc();
    if (userRef == null) return;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int currentStreak = 0;
      int longestStreak = 0;
      DateTime? lastLogin;

      if (snap.exists) {
        final data = snap.data()!;
        currentStreak = (data['currentStreak'] ?? 0) as int;
        longestStreak = (data['longestStreak'] ?? 0) as int;
        final lastLoginTs = data['lastLogin'] as Timestamp?;
        if (lastLoginTs != null) {
          final d = lastLoginTs.toDate();
          lastLogin = DateTime(d.year, d.month, d.day);
        }
      }

      if (lastLogin == null) {
        currentStreak = 1;
        longestStreak = currentStreak;
      } else {
        final diffDays = today.difference(lastLogin).inDays;
        if (diffDays == 0) {
          // same day - keep streak
        } else if (diffDays == 1) {
          currentStreak += 1;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else {
          // missed at least one day
          currentStreak = 1;
        }
      }

      tx.set(userRef, {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastLogin': today, // saved as Timestamp by Firestore SDK
      }, SetOptions(merge: true));
    });
  }

  Stream<int> currentStreakStream() {
    final userRef = _userDoc();
    if (userRef == null) return const Stream<int>.empty();
    return userRef.snapshots().map((doc) {
      return (doc.data()?['currentStreak'] ?? 0) as int;
    });
  }

  Stream<int> longestStreakStream() {
    final userRef = _userDoc();
    if (userRef == null) return const Stream<int>.empty();
    return userRef.snapshots().map((doc) {
      return (doc.data()?['longestStreak'] ?? 0) as int;
    });
  }
}


