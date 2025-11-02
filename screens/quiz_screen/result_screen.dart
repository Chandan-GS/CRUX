import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/screens/dashboard_screen.dart';
import 'package:quiz_app/screens/quiz_screen/quiz_screen.dart';
import 'package:quiz_app/services/firestore_service.dart';

class ResultScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const ResultScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Get FirebaseAuth instance

  late Future<Quiz?> _quizFuture;
  int? _expandedIndex;
  Quiz? _fetchedQuiz; // Store the quiz data for the retake function

  int _calculateScore(Quiz quiz) {
    int correctAnswers = 0;
    final questions = quiz.questions;

    for (int i = 0; i < questions.length; i++) {
      final userAnswer = quiz.userAnswers[i.toString()];
      final correctAnswer = questions[i].correctAnswer;

      if (userAnswer == correctAnswer) {
        correctAnswers++;
      }
    }

    return correctAnswers;
  }

  @override
  void initState() {
    super.initState();

    // Get the current user's ID
    final String? uid = _auth.currentUser?.uid;

    if (uid == null) {
      // If user is not logged in, set Future to an error
      _quizFuture = Future.error('User not authenticated.');
    } else {
      // User is logged in, fetch the quiz
      _quizFuture = _firestoreService.getQuizById(uid, widget.quizId);
    }
  }

  void _navigateToRetake() {
    // Check if the quiz data has been loaded
    if (_fetchedQuiz == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait for results to load.")),
      );
      return;
    }

    final quiz = _fetchedQuiz!;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          quizTitle: "${quiz.quizTitle} .R",
          questions: quiz.questions,
          difficulty: quiz.difficulty,
          duration: quiz.duration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: _navigateToRetake, // Call the navigation function
              child: Text(
                "Retake",
                style: GoogleFonts.robotoCondensed(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              }, // Call the navigation function
              child: Text(
                "Close",
                style: GoogleFonts.robotoCondensed(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Quiz?>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Error loading results: ${snapshot.error ?? "Quiz not found."}',
              ),
            );
          }

          final quiz = snapshot.data!;
          _fetchedQuiz = quiz; // Save the quiz data
          final questions = quiz.questions;
          final score = _calculateScore(quiz); // Calculate the score

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.5),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "$score",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 150,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -10.0,
                            color: Theme.of(context).colorScheme.secondary,
                            height: 1.0,
                          ),
                        ),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            "OUT OF",
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 2.0,
                              color: const Color(0xFF2D3436),
                            ),
                          ),
                        ),
                        Text(
                          "${questions.length}",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 150,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -10.0,
                            color: const Color(0xFFF39C12),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      final userAnswer = quiz.userAnswers[index.toString()];
                      final correctAnswer = question.correctAnswer;
                      final isCorrect = userAnswer == correctAnswer;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${index + 1}: ${question.questionText}',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      mainAxisSize:
                                          MainAxisSize.min, // Important
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildAnswerTile(
                                          context,
                                          title:
                                              '${userAnswer ?? "Not answered"}',
                                          isCorrect: isCorrect,
                                        ),
                                        if (!isCorrect) ...[
                                          const SizedBox(height: 8),
                                          _buildAnswerTile(
                                            context,
                                            title: '$correctAnswer',
                                            isCorrect:
                                                true, // This tile is always "correct"
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    icon: Icon(
                                      _expandedIndex == index
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _expandedIndex = _expandedIndex == index
                                            ? null
                                            : index;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              if (_expandedIndex == index)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12.5),
                                      Text(
                                        "Explanation",
                                        style: GoogleFonts.roboto(
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        question.explanation,
                                        style: GoogleFonts.roboto(
                                          fontWeight: FontWeight.normal,
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnswerTile(
    BuildContext context, {
    required String title,
    required bool isCorrect,
  }) {
    // Correct answer is tertiary, wrong/not answered is secondary
    final color = isCorrect
        ? Colors.black
        : Theme.of(context).colorScheme.primary;

    final icon = isCorrect ? Icons.check_rounded : Icons.close_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: isCorrect
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Fit content
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),

          Flexible(
            child: Text(
              title,
              style: GoogleFonts.robotoCondensed(color: color, fontSize: 14),
            ),
          ),
          // --- END OF UI CORRECTION ---
        ],
      ),
    );
  }
}
