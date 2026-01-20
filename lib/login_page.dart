import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fretfly/auth_service.dart';
import 'package:fretfly/home_page.dart';
import 'package:fretfly/signup_page.dart';
import 'package:fretfly/validation.dart';
import 'package:fretfly/ui/app_theme.dart';

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
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
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
    debugPrint(
      'LIFECYCLE state = $state, pendingAppleNavigation=$_pendingAppleNavigation',
    );
    if (state == AppLifecycleState.resumed && _pendingAppleNavigation) {
      _pendingAppleNavigation = false;
      if (!mounted) return;
      debugPrint('LIFECYCLE: app resumed -> navigating to Home');
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      debugPrint('SIGNIN error: $e\n$st');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      debugPrint('GOOGLE: error $e\n$st');
      if (!mounted) return;
      setState(() => _isOauthSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google sign-in failed')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      _pendingAppleNavigation = false;
      debugPrint('APPLE: error $e\n$st');
      if (!mounted) return;
      setState(() => _isOauthSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Apple sign-in failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryBrand, AppTheme.secondaryBrand],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo aplikace
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.asset(
                          'assets/logo/logo-fretfly.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vítej zpět!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Přihlas se a pokračuj v učení',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // White card with form
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Form(
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
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscured,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Heslo',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _isObscured = !_isObscured,
                                  ),
                                  icon: Icon(
                                    _isObscured
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Prosím zadej heslo'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  'Zapomněl jsi heslo?',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: _isSubmitting ? null : _onSubmit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Přihlásit se',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'nebo',
                                    style: TextStyle(
                                      color: AppTheme.mutedText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isOauthSubmitting
                                        ? null
                                        : _onGoogle,
                                    icon: Image.asset(
                                      'assets/icons/google.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    label: const Text(
                                      'Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (Platform.isIOS)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isOauthSubmitting
                                          ? null
                                          : _onApple,
                                      icon: Image.asset(
                                        'assets/icons/apple.png',
                                        width: 18,
                                        height: 18,
                                      ),
                                      label: const Text(
                                        'Apple',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nemáš účet? ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(SignUpPage.routeName),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          child: const Text(
                            'Registruj se',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
