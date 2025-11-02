import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/components/text_field.dart'; // You can remove this if noQuestions was the last widget using it
import 'package:quiz_app/components/difficulty_slider.dart';
import 'package:quiz_app/screens/dashboard_screen.dart';
import 'package:quiz_app/screens/quiz_screen/quiz_screen.dart';
import 'package:quiz_app/services/pdf_service.dart';
import 'package:quiz_app/services/gemini_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class QuizInput extends StatefulWidget {
  const QuizInput({
    super.key,
    this.file, // File is now optional
    this.content,
    required this.isPDF,
  }) : assert(
         isPDF ? file != null : content != null,
         'A file must be provided if isPDF is true; content must be provided if isPDF is false',
       );

  final File? file; // Changed to nullable
  final String? content;
  final bool isPDF;

  @override
  State<QuizInput> createState() => _QuizInputState();
}

class _QuizInputState extends State<QuizInput> {
  PDFService pdfService = PDFService();
  QuizApiService geminiService = QuizApiService();

  late TextEditingController quizName;
  late TextEditingController time;
  late TextEditingController noQuestions;
  late String difficulty = "Medium";

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
      // 1. Validate inputs
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
      if (noQuestions.text.isEmpty || int.parse(noQuestions.text) > 20) {
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

      setState(() {
        _isLoading = true;
      });

      String quizContextText;

      if (widget.isPDF) {
        quizContextText = await pdfService.extractTextFromPDF(widget.file!);
      } else {
        quizContextText = widget.content!;
      }

      if (quizContextText.trim().isEmpty) {
        throw Exception('No text found to generate a quiz from.');
      }

      // 3. Generate quiz using Gemini
      final questionJson = await geminiService.generateQuiz(
        quizContextText,
        quizName.text,
        int.parse(
          noQuestions.text,
        ), // No need for ternary, we checked for empty
        difficulty,
      );

      debugPrint('Generated Question JSON: $questionJson');

      if (!mounted) return;

      // 4. Navigate to quiz screen
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
            child: Container(
              margin: const EdgeInsets.fromLTRB(25, 25, 25, 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  widget.isPDF
                      ? Container(
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SfPdfViewer.file(
                            canShowScrollHead: true,
                            widget.file!,
                            pageLayoutMode: PdfPageLayoutMode.continuous,
                            pageSpacing: 2,
                            enableDoubleTapZooming: true,
                          ),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 32),
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

                      // --- THIS IS THE UPDATED WIDGET ---
                      Expanded(
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: TextField(
                              controller: noQuestions,
                              textAlign: TextAlign.center,
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
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical:
                                      15, // Adjust vertical padding as needed
                                ),
                                hintText: "No. Qs",
                                hintStyle: GoogleFonts.robotoCondensed(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.5),
                                ),
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // --- END OF UPDATED WIDGET ---
                    ],
                  ),
                  const SizedBox(height: 32),
                  DifficultySlider(
                    initialDifficulty: 'Medium',
                    onChanged: (String newDifficulty) {
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
                                        fontWeight: FontWeight.normal,
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
                                Navigator.pushReplacement(
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

// This dialog code is unchanged and correct
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
                  color: Theme.of(context).colorScheme.secondary,
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
            style: GoogleFonts.robotoCondensed(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
