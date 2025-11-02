import 'package:cloud_firestore/cloud_firestore.dart';

class QuizScore {
  final String userId;
  final String username;
  final int score;
  final Timestamp submittedAt;

  QuizScore({
    required this.userId,
    required this.username,
    required this.score,
    required this.submittedAt,
  });

  factory QuizScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizScore(
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      score: data['score'] ?? 0,
      submittedAt: data['submittedAt'] ?? Timestamp.now(),
    );
  }
}
