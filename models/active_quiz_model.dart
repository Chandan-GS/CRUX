import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/models/question_model.dart';

/// A model class for the live game data stored in 'activeQuizzes'
class ActiveQuiz {
  final List<Question> questions;
  final int currentQuestionIndex;

  /// Stores answers in a nested map:
  /// {
  ///   "0": { // Question Index
  ///     "user_uid_1": {"answer": "Paris", "timestamp": ...},
  ///     "user_uid_2": {"answer": "London", "timestamp": ...}
  ///   },
  ///   "1": { ... }
  /// }
  final Map<String, dynamic> answers;

  ActiveQuiz({
    required this.questions,
    required this.currentQuestionIndex,
    required this.answers,
  });

  factory ActiveQuiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse the list of question objects
    final questionsList = data['questions'] as List<dynamic>? ?? [];
    final questions = questionsList
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();

    return ActiveQuiz(
      questions: questions,
      currentQuestionIndex: data['currentQuestionIndex'] ?? 0,
      answers: data['answers'] as Map<String, dynamic>? ?? {},
    );
  }

  // Helper to check if a user has answered the current question
  bool hasUserAnswered(String uid, int questionIndex) {
    final questionAnswers = answers[questionIndex.toString()];
    if (questionAnswers != null &&
        questionAnswers is Map &&
        questionAnswers.containsKey(uid)) {
      return true;
    }
    return false;
  }
}
