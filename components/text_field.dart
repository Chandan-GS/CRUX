import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizTextField extends StatefulWidget {
  const QuizTextField({
    super.key,
    required this.controller,
    required this.text,
    required this.isPassword,
  });

  final TextEditingController controller;
  final String text;
  final bool isPassword;

  @override
  State<QuizTextField> createState() => _QuizTextFieldState();
}

class _QuizTextFieldState extends State<QuizTextField> {
  // State variable to track if the password should be hidden or not
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    // When the widget is first built, set its obscured state
    // based on whether it's a password field.
    _isObscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: TextField(
        cursorColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        style: GoogleFonts.robotoCondensed(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: Theme.of(context).colorScheme.secondary,
        ),
        controller: widget.controller,
        // The text is obscured if it's a password field AND _isObscured is true
        obscureText: _isObscured,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 5,
          ),
          floatingLabelStyle: GoogleFonts.robotoCondensed(
            color: Theme.of(context).colorScheme.secondary,
          ),
          hintText: widget.text,
          hintStyle: GoogleFonts.robotoCondensed(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          // --- LOGIC FOR THE ICON ---
          suffixIcon: widget.isPassword
              ? IconButton(
                  // Aligns the icon nicely
                  padding: const EdgeInsets.only(right: 12.0),
                  icon: Icon(
                    // Change the icon based on the state
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.7),
                  ),
                  onPressed: () {
                    // Toggle the state
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : null, // If it's not a password field, show no icon
        ),
      ),
    );
  }
}
