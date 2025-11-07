import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fretfly/auth_service.dart';
import 'package:fretfly/home_page.dart';
import 'package:fretfly/signup_page.dart';
import 'package:fretfly/validation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscured = true;
  bool _isSubmitting = false;
  bool _isOauthSubmitting = false;

  // fallbacky pro Apple sign-in (ponecháno), ale hlavní řešení: poslouchat auth state
  bool _pendingAppleNavigation = false;

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Hlavní robustní řešení: posloucháme authStateChanges a navigujeme, pokud uživatel je přihlášen.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('AUTH STATE change: $user');
      if (user != null) {
        // navigovat přes rootNavigator a odstranit stack
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          debugPrint('AUTH: navigating to Home because user != null');
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('LIFECYCLE state = $state, pendingAppleNavigation=$_pendingAppleNavigation');
    if (state == AppLifecycleState.resumed && _pendingAppleNavigation) {
      _pendingAppleNavigation = false;
      if (!mounted) return;
      debugPrint('LIFECYCLE: app resumed -> navigating to Home');
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      await AuthService.instance.signIn(email: email, password: password);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // navigace proběhne také přes authStateChanges listener; ale pro jistotu zavolat i přímo
      _navigateToHome();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      debugPrint('SIGNIN error: $e\n$st');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }
  }

  Future<void> _onGoogle() async {
    setState(() => _isOauthSubmitting = true);
    debugPrint('GOOGLE: start signInWithGoogle()');

    try {
      await AuthService.instance.signInWithGoogle();
      debugPrint('GOOGLE: completed');

      if (!mounted) return;
      setState(() => _isOauthSubmitting = false);

      // navigace se provede skrz authStateChanges listener; volání zde jako fallback
      _navigateToHome();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isOauthSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      debugPrint('GOOGLE: error $e\n$st');
      if (!mounted) return;
      setState(() => _isOauthSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in failed')));
    }
  }

  Future<void> _onApple() async {
    setState(() => _isOauthSubmitting = true);
    debugPrint('APPLE: start signInWithApple()');

    try {
      await AuthService.instance.signInWithApple();
      debugPrint('APPLE: signInWithApple() completed');

      if (!mounted) return;
      setState(() => _isOauthSubmitting = false);

      // Ponecháme fallbacky, ale hlavní navigace je driven auth state listenerem.
      _pendingAppleNavigation = true;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      debugPrint('APPLE: lifecycle=$lifecycle');

      if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
        _pendingAppleNavigation = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          debugPrint('APPLE: navigating to Home (immediate fallback)');
          _navigateToHome();
        });
        return;
      }

      debugPrint('APPLE: waiting for app resume, setting fallback timer');
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!_pendingAppleNavigation) return;
        _pendingAppleNavigation = false;
        if (!mounted) return;
        debugPrint('APPLE: fallback navigating to Home');
        _navigateToHome();
      });
    } on AuthException catch (e) {
      _pendingAppleNavigation = false;
      if (!mounted) return;
      setState(() => _isOauthSubmitting = false);
      debugPrint('APPLE: AuthException: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      _pendingAppleNavigation = false;
      debugPrint('APPLE: error $e\n$st');
      if (!mounted) return;
      setState(() => _isOauthSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apple sign-in failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.music_note, size: 64),
                const SizedBox(height: 12),
                Text(
                  'Fretfly',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscured,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _isObscured = !_isObscured),
                            icon: Icon(
                              _isObscured ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please enter your password'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _onSubmit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Log in'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isOauthSubmitting ? null : _onGoogle,
                        icon: Image.asset(
                          'assets/icons/google.png',
                          width: 20,
                          height: 20,
                        ),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (Platform.isIOS)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isOauthSubmitting ? null : _onApple,
                          icon: Image.asset(
                            'assets/icons/apple.png',
                            width: 18,
                            height: 18,
                          ),
                          label: const Text('Apple'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(SignUpPage.routeName),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}