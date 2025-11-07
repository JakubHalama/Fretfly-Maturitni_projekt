class Validators {
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? strongPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Please enter a password';
    if (text.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(text)) {
      return 'Add an uppercase letter (A-Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(text)) return 'Add a lowercase letter (a-z)';
    if (!RegExp(r'[0-9]').hasMatch(text)) return 'Add a number (0-9)';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>\[\]\-_=+;/\\]').hasMatch(text)) {
      return 'Add a special character (!@#£ etc.)';
    }
    return null;
  }

  static String? confirmPassword(String? value, String other) {
    if (value != other) return 'Passwords do not match';
    return null;
  }
}
