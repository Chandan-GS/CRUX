import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/components/text_field.dart';
import 'package:quiz_app/components/difficulty_slider.dart';
import 'package:quiz_app/screens/dashboard_screen.dart';
import 'package:quiz_app/screens/quiz_screen/quiz_screen.dart';
import 'package:quiz_app/services/gemini_service.dart';
import 'package:quiz_app/services/pdf_service.dart';
import 'package:quiz_app/models/question_model.dart';

class CustomQuizInput extends StatefulWidget {
  final Set<String> categories;

  const CustomQuizInput({super.key, required this.categories});

  @override
  State<CustomQuizInput> createState() => _CustomQuizInputState();
}

class _CustomQuizInputState extends State<CustomQuizInput> {
  // PDFService is not used here, but kept from original code
  PDFService pdfService = PDFService();
  QuizApiService geminiService = QuizApiService();

  late TextEditingController quizName;
  late TextEditingController time;
  late TextEditingController noQuestions;
  late String difficulty = "Medium";

  // pdfText is not used here, but kept from original code
  late Future<String> pdfText;
  String _selectedTime = "00:00";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    quizName = TextEditingController();
    time = TextEditingController();
    time.text = "00:00";
    noQuestions = TextEditingController();
  }

  @override
  void dispose() {
    quizName.dispose();
    time.dispose();
    noQuestions.dispose();
    super.dispose();
  }

  Future<void> _showTimeInputDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return _TimeInputDialog(
          onSave: (minutes) {
            final formattedTime = '${minutes.toString().padLeft(2, '0')} min';
            setState(() {
              _selectedTime = formattedTime;
            });
            time.text = formattedTime;
          },
        );
      },
    );
  }

  Future<void> _handleStartQuiz() async {
    try {
      // Validate inputs
      if (quizName.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a quiz name',
              style: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
        return;
      }
      if (noQuestions.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter number of questions',
              style: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
        return;
      }
      // --- ADDED: Validate categories ---
      if (widget.categories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No categories selected',
              style: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final List<Question> questionJson = await geminiService
          .generateCustomQuiz(
            categories: widget.categories,
            difficulty: difficulty,
            questionCount: int.tryParse(noQuestions.text) ?? 5,
          );

      debugPrint('Generated ${questionJson.length} questions');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            questions: questionJson,
            quizTitle: quizName.text,
            difficulty: difficulty,
            duration: time.text,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Categories:",
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.5),

                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: widget.categories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 200),
                  QuizTextField(
                    controller: quizName,
                    text: "Quiz Name",
                    isPassword: false,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _showTimeInputDialog,
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 30,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                Text(
                                  _selectedTime,
                                  style: GoogleFonts.robotoCondensed(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: QuizTextField(
                          isPassword: false,
                          controller: noQuestions,
                          text: "no. questions",

                          // --- END ---
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  DifficultySlider(
                    initialDifficulty: 'Medium', // Pass in the initial string
                    onChanged: (String newDifficulty) {
                      // newDifficulty will be 'Easy', 'Medium', or 'Hard'
                      print('Selected difficulty: $newDifficulty');
                      setState(() {
                        difficulty = newDifficulty;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleStartQuiz,
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      "Start Quiz",
                                      style: GoogleFonts.robotoCondensed(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DashboardScreen(),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.close_rounded, size: 30),
                      ),
                      const SizedBox(width: 32),
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
}

class _TimeInputDialog extends StatefulWidget {
  final Function(int minutes) onSave;

  const _TimeInputDialog({required this.onSave});

  @override
  State<_TimeInputDialog> createState() => _TimeInputDialogState();
}

class _TimeInputDialogState extends State<_TimeInputDialog> {
  late final TextEditingController minuteController;

  @override
  void initState() {
    super.initState();
    minuteController = TextEditingController();
  }

  @override
  void dispose() {
    minuteController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final minutes = int.tryParse(minuteController.text) ?? 0;

    if (minutes >= 0) {
      widget.onSave(minutes);
      Navigator.of(context).pop();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          Expanded(
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                cursorColor: Theme.of(
                  context,
                ).colorScheme.secondary.withOpacity(0.5),
                style: GoogleFonts.robotoCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
                controller: minuteController,
                obscureText: false,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 5,
                  ),
                  floatingLabelStyle: GoogleFonts.robotoCondensed(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  hintText: "Minutes",
                  hintStyle: GoogleFonts.robotoCondensed(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.2),
                  ),
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: Text(
            'Save',
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
