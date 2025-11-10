import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'services/streak_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String _keyCurrentUser = 'auth_current_user';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> isSignedIn() async {
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<String?> currentUserEmail() async {
    return FirebaseAuth.instance.currentUser?.email;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    final p = await _prefs;
    await p.remove(_keyCurrentUser);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await StreakService().updateOnLogin();
      final p = await _prefs;
      await p.setString(
        _keyCurrentUser,
        FirebaseAuth.instance.currentUser?.email ?? '',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await StreakService().updateOnLogin();
      final p = await _prefs;
      await p.setString(
        _keyCurrentUser,
        FirebaseAuth.instance.currentUser?.email ?? '',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithProvider(
        GoogleAuthProvider(),
      );
      await StreakService().updateOnLogin();
      final p = await _prefs;
      await p.setString(
        _keyCurrentUser,
        credential.user?.email ??
            FirebaseAuth.instance.currentUser?.email ??
            '',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<void> signInWithApple() async {
    try {
      // Zkusíme jednodušší přístup - bez scope
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );

      print('Apple Sign-In Debug:');
      print(
        '- Identity Token: ${appleCred.identityToken != null ? "OK" : "NULL"}',
      );
      print('- Authorization Code: ${"OK"}');
      print('- User ID: ${appleCred.userIdentifier}');
      print('- Email: ${appleCred.email}');

      // Debug: zkontroluj, jestli máme tokeny
      if (appleCred.identityToken == null) {
        throw AuthException('Apple Sign-In failed: No identity token received');
      }

      final oauth = OAuthProvider('apple.com');
      final credential = oauth.credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
      );

      print('Firebase credential created, attempting sign-in...');

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      print('Firebase sign-in result:');
      print('- User: ${userCredential.user != null ? "OK" : "NULL"}');
      print('- Email: ${userCredential.user?.email}');
      print('- UID: ${userCredential.user?.uid}');

      // Debug: zkontroluj, jestli se uživatel přihlásil
      if (userCredential.user == null) {
        throw AuthException(
          'Apple Sign-In failed: No user returned from Firebase',
        );
      }

      final p = await _prefs;
      await p.setString(_keyCurrentUser, userCredential.user?.email ?? '');

      print('Apple Sign-In successful!');
      await StreakService().updateOnLogin();
    } on SignInWithAppleAuthorizationException catch (e) {
      print('Apple Sign-In Authorization Exception: ${e.code} - ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) return; // user cancelled
      throw AuthException('Apple sign-in failed: ${e.message}');
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw AuthException('Firebase error: ${_mapFirebaseError(e)}');
    } catch (e) {
      print('General Exception: $e');
      throw AuthException('Apple sign-in failed: $e');
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found for this email';
      case 'wrong-password':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Authentication error (${e.code})';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
