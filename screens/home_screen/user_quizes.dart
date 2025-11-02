import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/screens/quiz_screen/quiz_screen.dart';

class UserQuizes extends StatelessWidget {
  final List<Quiz> quizzes;
  final Set<String> favoriteQuizIds;
  final Function(String) onToggleFavorite;
  final Function(String) onDeleteQuiz;

  const UserQuizes({
    super.key,
    required this.quizzes,
    required this.favoriteQuizIds,
    required this.onToggleFavorite,
    required this.onDeleteQuiz,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yy').format(date);
  }

  int _calculateScore(Quiz quiz) {
    int correctAnswers = 0;
    final questions = quiz.questions;

    if (quiz.userAnswers.length < questions.length) {
      // Handle error
    }

    for (int i = 0; i < questions.length; i++) {
      final userAnswer = quiz.userAnswers[i.toString()];
      final correctAnswer = questions[i].correctAnswer;

      if (userAnswer == correctAnswer) {
        correctAnswers++;
      }
    }

    return correctAnswers;
  }

  Widget _buildSwipeAction({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: GoogleFonts.robotoCondensed(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (alignment == Alignment.centerRight) ...[
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) {
      return Center(
        child: Text(
          'No quizzes here... yet!',
          style: GoogleFonts.robotoCondensed(
            fontSize: 18,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    }

    // --- SORTING LOGIC ADDED HERE ---
    // Create a new list to avoid modifying the original
    final sortedQuizzes = List<Quiz>.from(quizzes);
    // Sort by createdAt date, latest first (descending)
    sortedQuizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // --- END OF SORTING LOGIC ---

    return ListView.builder(
      clipBehavior: Clip.none,
      // Use the new sorted list
      itemCount: sortedQuizzes.length,
      itemBuilder: (context, index) {
        // Use the new sorted list
        final quiz = sortedQuizzes[index];
        final isFavorite = favoriteQuizIds.contains(quiz.quizId);

        return Dismissible(
          key: Key(quiz.quizId),
          background: _buildSwipeAction(
            context: context,
            icon: Icons.refresh_rounded,
            text: "Retake Quiz",
            color: const Color.fromARGB(255, 129, 169, 131),
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: _buildSwipeAction(
            context: context,
            icon: Icons.delete_outline_rounded,
            text: "Delete Quiz",
            color: const Color.fromARGB(255, 255, 98, 98),
            alignment: Alignment.centerRight,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // --- RETAKE ACTION WITH DIALOG ---
              final bool? shouldRetake = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    title: Text(
                      "Retake Quiz?",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    content: Text(
                      "Are you sure you want to retake this quiz? Your current progress will be replaced.",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          "Retake",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 38, 143, 42),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (shouldRetake == true) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      questions: quiz.questions,
                      quizTitle: quiz.quizTitle,
                      difficulty: quiz.difficulty,
                      duration: quiz.duration,
                    ),
                  ),
                );
              }
              return false;
            } else {
              // --- DELETE ACTION ---
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    title: Text(
                      "Delete Quiz?",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    content: Text(
                      "Are you sure you want to delete this quiz history? This action cannot be undone.",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          "Delete",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              onDeleteQuiz(quiz.quizId);
            }
          },
          child: _QuizListItem(
            quizId: quiz.quizId,
            title: quiz.quizTitle,
            duration: quiz.duration,
            date: _formatDate(quiz.createdAt),
            difficulty: quiz.difficulty,
            score: _calculateScore(quiz),
            totalQuestions: quiz.noOfQuestions,
            isFavorite: isFavorite,
            onToggleFavorite: () => onToggleFavorite(quiz.quizId),
          ),
        );
      },
    );
  }
}

class _QuizListItem extends StatelessWidget {
  final String quizId;
  final String title;
  final String duration;
  final String date;
  final String difficulty;
  final int score;
  final int totalQuestions;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _QuizListItem({
    required this.quizId,
    required this.title,
    required this.duration,
    required this.date,
    required this.difficulty,
    required this.score,
    required this.totalQuestions,
    required this.onToggleFavorite,
    this.isFavorite = false,
  });

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFFCFF0C7);
      case 'medium':
        return const Color(0xFFFFF8AA);
      case 'hard':
        return const Color(0xFFFCC0C0);
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color difficultyColor = _getDifficultyColor(difficulty);
    final double scoreProgress = totalQuestions > 0
        ? score / totalQuestions
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 24, right: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        overflow: TextOverflow.clip,
                        title,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isFavorite
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _InfoTag(icon: Icons.schedule_rounded, text: duration),
                    const SizedBox(width: 16),
                    _InfoTag(icon: Icons.calendar_month_rounded, text: date),
                    const SizedBox(width: 16),
                    _DifficultyTag(
                      difficulty: difficulty,
                      color: difficultyColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _ScoreIndicator(
            score: score,
            totalQuestions: totalQuestions,
            progress: scoreProgress,
          ),
        ],
      ),
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final double progress;

  const _ScoreIndicator({
    required this.score,
    required this.totalQuestions,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      width: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 16,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color.fromARGB(255, 255, 153, 0),
              ),
            ),
          ),
          Text(
            '$score/$totalQuestions',
            style: GoogleFonts.robotoCondensed(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.robotoCondensed(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _DifficultyTag extends StatelessWidget {
  final String difficulty;
  final Color color;

  const _DifficultyTag({required this.difficulty, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.robotoCondensed(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }
}
