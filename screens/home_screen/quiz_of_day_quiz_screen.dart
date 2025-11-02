import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/components/quiz_ui_widget.dart';
import 'package:quiz_app/components/timer.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/screens/quiz_screen/result_screen.dart';

import 'package:quiz_app/services/firestore_service.dart';

class QuizOfDayScreen extends StatefulWidget {
  final String quizTitle;
  final List<Question> questions;
  final String difficulty;
  final String duration;
  // This function expects an integer (the score)
  final Function(int) onQuizCompleted;

  const QuizOfDayScreen({
    super.key,
    required this.quizTitle,
    required this.questions,
    required this.difficulty,
    required this.duration,
    required this.onQuizCompleted,
  });

  @override
  State<QuizOfDayScreen> createState() => _QuizOfDayScreenState();
}

class _QuizOfDayScreenState extends State<QuizOfDayScreen> {
  late final PageController _pageController;
  final Map<int, String> _selectedAnswers = {};
  int _currentIndex = 0;
  bool _isSubmitting = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(int index, String option) {
    setState(() {
      if (_selectedAnswers.containsKey(index) &&
          _selectedAnswers[index] == option) {
        _selectedAnswers.remove(index);
      } else {
        _selectedAnswers[index] = option;
      }
    });
  }

  // --- NEW HELPER FUNCTION ---
  /// Calculates the final score based on selected answers.
  int _calculateScore() {
    int correctAnswers = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      // Get the user's answer for question 'i'
      final String? userAnswer = _selectedAnswers[i];
      final String correctAnswer = widget.questions[i].correctAnswer;

      if (userAnswer == correctAnswer) {
        correctAnswers++;
      }
    }
    return correctAnswers;
  }

  // --- MODIFIED FUNCTION ---
  Future<void> _saveAndNavigate() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // --- THIS IS THE FIX ---
      // 1. Calculate the final score
      final int finalScore = _calculateScore();

      // 2. Call the callback (from HomeScreen) to submit to the daily leaderboard
      // This is what triggers the FirestoreService.submitQuizOfTheDayScore
      widget.onQuizCompleted(finalScore);
      // --- END OF FIX ---

      // 3. Continue saving the quiz to the user's personal history
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user is signed in');
      }
      final String uid = currentUser.uid;

      // Convert Map<int, String> to Map<String, String> for Firestore
      final userAnswers = _selectedAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      // Use the saveQuiz method from your FirestoreService
      final String quizId = await _firestoreService.saveQuiz(
        uid: uid,
        quizTitle: widget.quizTitle,
        duration: widget.duration,
        difficulty: widget.difficulty,
        noOfQuestions: widget.questions.length,
        questions: widget.questions,
        userAnswers: userAnswers,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                ResultScreen(quizId: quizId, quizTitle: widget.quizTitle),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save quiz: ${e.toString()}',
              style: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("No questions were provided.")),
      );
    }

    final bool allQuestionsAnswered =
        _selectedAnswers.length == widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            widget.quizTitle,
            style: GoogleFonts.robotoCondensed(
              fontSize: 24,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: allQuestionsAnswered
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (allQuestionsAnswered) {
                        _saveAndNavigate();
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('End Quiz?'),
                            content: const Text(
                              'Are you sure you want to submit? Your progress will be saved.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _saveAndNavigate();
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      allQuestionsAnswered ? "Submit" : "End",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: allQuestionsAnswered
                            ? Colors.black
                            : Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.questions.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(25, 16, 25, 16),
                    child: QuizUIWidget(
                      questionText: question.questionText,
                      options: question.options,
                      selectedOption: _selectedAnswers[index],
                      onOptionSelected: (option) {
                        _handleOptionSelected(index, option);
                      },
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: TickingTimer(
                          minutes:
                              int.tryParse(widget.duration.split(' ')[0]) ?? 0,
                        ),
                      ),
                    ],
                  ),
                  CircleQuestionList(
                    itemCount: widget.questions.length,
                    answeredQuestions: _selectedAnswers,
                    currentIndex: _currentIndex,
                    onIndexChanged: (index) {
                      _pageController.jumpToPage(index);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The CircleQuestionList widget remains unchanged
class CircleQuestionList extends StatelessWidget {
  final int itemCount;
  final void Function(int) onIndexChanged;
  final Map<int, String> answeredQuestions;
  final int currentIndex;

  const CircleQuestionList({
    super.key,
    required this.itemCount,
    required this.onIndexChanged,
    required this.answeredQuestions,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
        ),
        itemBuilder: (context, index) {
          final bool isSelected = currentIndex == index;
          final bool isAnswered = answeredQuestions.containsKey(index);
          final double size = isSelected ? 80.0 : 50.0;
          final Color circleColor = isAnswered
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.secondary;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () => onIndexChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isAnswered
                          ? Colors.black
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
