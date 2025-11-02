import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';

class Quiz {
  final String quizId;
  final String quizTitle;
  final String duration;
  final String difficulty;
  final int noOfQuestions;
  final List<Question> questions;
  final Map<String, String> userAnswers;
  final DateTime createdAt;

  Quiz({
    required this.quizId,
    required this.quizTitle,
    required this.duration,
    required this.difficulty,
    required this.noOfQuestions,
    required this.questions,
    required this.userAnswers,
    required this.createdAt,
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // --- FIX IS HERE ---
    // Get the createdAt field from data
    final dynamic createdAtData = data['createdAt'];
    DateTime parsedCreatedAt;

    // Check if it's a Firestore Timestamp and convert it
    if (createdAtData is Timestamp) {
      parsedCreatedAt = createdAtData.toDate();
    } else {
      // Fallback if the field is null or not a Timestamp
      // We use DateTime.now() as a fallback, but the data
      // should ideally always have a valid Timestamp.
      parsedCreatedAt = DateTime.now();
    }
    // --- END OF FIX ---

    return Quiz(
      quizId: data['quizId'] ?? doc.id,
      quizTitle: data['quizTitle'] ?? '',
      duration: data['duration'] ?? '',
      difficulty: data['difficulty'] ?? '',
      noOfQuestions: data['noOfQuestions'] ?? 0,
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList(),
      userAnswers: Map<String, String>.from(data['userAnswers'] ?? {}),
      // Use the parsed date from Firestore
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'duration': duration,
      'difficulty': difficulty,
      'noOfQuestions': noOfQuestions,
      'questions': questions.map((q) => q.toMap()).toList(),
      'userAnswers': userAnswers,
      // This is correct. It will save the DateTime as a Timestamp.
      'createdAt': createdAt,
    };
  }
}
