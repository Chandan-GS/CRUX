import 'dart:async'; // Import for the Timer (debouncer)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/components/text_field.dart';
import 'package:quiz_app/screens/login_screen.dart';
// These imports assume your services are in separate files as we discussed
import 'package:quiz_app/services/firebase_service.dart';
import 'package:quiz_app/services/firestore_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final TextEditingController email;
  late final TextEditingController password;
  late final TextEditingController confirmPassword;
  late final TextEditingController username;

  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();

  bool _isCheckingUsername = false;
  bool?
  _isUsernameAvailable; // null: not checked, true: available, false: taken
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    email = TextEditingController();
    password = TextEditingController();
    confirmPassword = TextEditingController();
    username = TextEditingController();
    username.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    // Clean up listeners and timers to prevent memory leaks
    username.removeListener(_onUsernameChanged);
    _debounce?.cancel();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    username.dispose();
    super.dispose();
  }

  /// Debounces the username check to avoid spamming Firestore.
  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability();
    });
  }

  /// Checks username availability and updates the UI.
  Future<void> _checkUsernameAvailability() async {
    final currentUsername = username.text.trim();
    if (currentUsername.length < 4) {
      setState(() {
        _isUsernameAvailable = null; // Reset status for short usernames
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    final isAvailable = await _firestore.isUsernameAvailable(currentUsername);

    if (!mounted)
      return; // Ensure widget is still visible before updating state

    setState(() {
      _isUsernameAvailable = isAvailable;
      _isCheckingUsername = false;
    });
  }

  /// Handles the signup button press with validation.
  Future<void> _handleSignup() async {
    // --- Form Validation ---
    if (username.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "All fields are required.",
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      );
      return;
    }
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Passwords do not match.",
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      );
      return;
    }
    if (_isUsernameAvailable == null || !_isUsernameAvailable!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please choose an available username.",
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      );
      return;
    }
    // --- End Validation ---

    try {
      await _auth.signUpWithEmail(
        email.text.trim(),
        password.text.trim(),
        username.text.trim(), // Pass the validated username
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Signup successful! Please login.",
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Added for smaller screens
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Signup to Crux',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      // Using theme colors for adaptability
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  QuizTextField(
                    controller: username,
                    text: 'Username',
                    isPassword: false,
                  ),
                  // --- Username Status Indicator UI ---
                  _buildUsernameStatus(),
                  const SizedBox(height: 16.0), // Adjusted spacing
                  QuizTextField(
                    controller: email,
                    text: "Email",
                    isPassword: false,
                  ),
                  const SizedBox(height: 32.0),
                  QuizTextField(
                    controller: password,
                    text: "Password",
                    isPassword: true,
                  ),
                  const SizedBox(height: 32.0),
                  QuizTextField(
                    controller: confirmPassword,
                    text: "Confirm Password",
                    isPassword: true,
                  ),
                  const SizedBox(height: 32.0),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: _handleSignup, // Use the handler method
                      child: Text(
                        'Signup',
                        style: GoogleFonts.robotoCondensed(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.robotoCondensed(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, a1, a2) =>
                                  const LoginScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                        child: Text(
                          "Login",
                          style: GoogleFonts.robotoCondensed(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A helper widget to build the username availability status indicator.
  Widget _buildUsernameStatus() {
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.only(top: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Checking availability...'),
          ],
        ),
      );
    }

    if (username.text.length < 4 && username.text.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12.0),
        child: Text(
          'Username must be at least 4 characters',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    if (_isUsernameAvailable != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isUsernameAvailable! ? Icons.check_circle : Icons.cancel,
              color: _isUsernameAvailable! ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _isUsernameAvailable!
                  ? 'Username is available!'
                  : 'This username is already taken.',
              style: GoogleFonts.robotoCondensed(
                color: _isUsernameAvailable! ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox(height: 32);
  }
}
