import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/models/active_quiz_model.dart';
import 'package:quiz_app/models/trivia_room_model.dart';
import 'package:quiz_app/screens/dashboard_screen.dart';
import 'package:quiz_app/screens/trivia_screen/trivia_screen.dart';
import 'package:quiz_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TriviaResultScreen extends StatefulWidget {
  final String roomCode;
  final String triviaName;

  const TriviaResultScreen({
    super.key,
    required this.roomCode,
    required this.triviaName,
  });

  @override
  State<TriviaResultScreen> createState() => _TriviaResultScreenState();
}

class _TriviaResultScreenState extends State<TriviaResultScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  late Future<Map<String, dynamic>> _resultsDataFuture;
  bool _isAdmin = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _resultsDataFuture = _loadResultsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WillPopScope(
        onWillPop: () async => !_isDeleting,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _resultsDataFuture,
          builder: (context, snapshot) {
            // --- Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- Error State ---
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Error loading results: ${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                          (route) => false,
                        ),
                        child: const Text("Go Home"),
                      ),
                    ],
                  ),
                ),
              );
            }

            // --- No Data State ---
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No results available"));
            }

            // --- Success State ---
            final data = snapshot.data!;
            final activeQuiz = data['activeQuiz'] as ActiveQuiz?;
            final participants =
                data['participants'] as List<TriviaParticipant>? ?? [];
            final scores = data['scores'] as Map<String, int>? ?? {};
            final sortedScores =
                data['sortedScores'] as List<MapEntry<String, int>>? ?? [];

            if (activeQuiz == null) {
              return const Center(child: Text("Could not load quiz data."));
            }

            _isAdmin = participants.any(
              (p) => p.uid == _currentUserId && p.isAdmin,
            );

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      if (sortedScores.isNotEmpty)
                        _buildWinnerPodium(sortedScores, participants)
                      else
                        const Center(
                          child: Text(
                            "No scores to display.",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 32),
                      if (sortedScores.isNotEmpty)
                        _buildScoreChart(
                          sortedScores,
                          participants,
                          activeQuiz.questions.length,
                        )
                      else
                        const SizedBox.shrink(),
                      const SizedBox(height: 32),
                      if (sortedScores.isNotEmpty)
                        _buildLeaderboard(
                          sortedScores,
                          participants,
                          scores,
                          activeQuiz.questions.length,
                        )
                      else
                        const SizedBox.shrink(),
                      const SizedBox(height: 40),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// --- UPDATED SCORING LOGIC ---
  Future<Map<String, dynamic>> _loadResultsData() async {
    try {
      final activeQuiz = await _firestoreService.getActiveQuizOnce(
        widget.roomCode,
      );
      if (activeQuiz == null) {
        throw Exception(
          'Active quiz data could not be loaded for room ${widget.roomCode}.',
        );
      }

      final participantsList = await _firestoreService
          .getTriviaParticipantsOnce(widget.roomCode);
      // Initialize scores for all participants found in the participant list
      final scores = {for (var p in participantsList) p.uid: 0};

      final totalQuestions = activeQuiz.questions.length;

      // Iterate through each question to calculate points
      for (int i = 0; i < totalQuestions; i++) {
        final correctAnswer = activeQuiz.questions[i].correctAnswer;
        final questionAnswersRaw =
            activeQuiz.answers[i.toString()] as Map<String, dynamic>?;

        if (questionAnswersRaw == null || questionAnswersRaw.isEmpty) {
          continue; // No one answered this question
        }

        // Filter for correct answers and parse timestamp
        List<MapEntry<String, Timestamp>> correctAnswersWithTime = [];
        questionAnswersRaw.forEach((uid, answerData) {
          if (answerData is Map && answerData['answer'] == correctAnswer) {
            // Ensure timestamp exists and is a Timestamp object
            if (answerData['timestamp'] is Timestamp) {
              correctAnswersWithTime.add(
                MapEntry(uid, answerData['timestamp'] as Timestamp),
              );
            } else {
              print(
                "Warning: Missing or invalid timestamp for user $uid on question $i",
              );
              // Assign a late timestamp if missing to rank them last among correct answers
              correctAnswersWithTime.add(MapEntry(uid, Timestamp.now()));
            }
          }
        });

        if (correctAnswersWithTime.isEmpty) {
          continue; // No one answered this question correctly
        }

        // Sort correct answers by timestamp (earliest first)
        correctAnswersWithTime.sort((a, b) => a.value.compareTo(b.value));

        // Award points based on rank
        for (int rank = 0; rank < correctAnswersWithTime.length; rank++) {
          final entry = correctAnswersWithTime[rank];
          final String participantUid = entry.key;
          int points = 0;
          if (rank == 0) {
            // 1st place
            points = 10;
          } else if (rank == 1) {
            // 2nd place
            points = 8;
          } else if (rank == 2) {
            // 3rd place
            points = 6;
          } else {
            // 4th place onwards
            points = 5;
          }

          // Add points to the participant's score, ensuring UID exists in scores map
          if (scores.containsKey(participantUid)) {
            scores[participantUid] = scores[participantUid]! + points;
          } else {
            // This case might happen if a participant joined, answered, then left,
            // and wasn't in the final participantsList. We can add them back.
            print(
              "Warning: Scored participant $participantUid not found in initial list. Adding.",
            );
            scores[participantUid] = points;
          }
        }
      }

      // Sort final scores (descending)
      final sortedScores = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      print(
        "Results loaded successfully for ${widget.roomCode}. Scores: $scores",
      );
      return {
        'activeQuiz': activeQuiz,
        'participants': participantsList,
        'scores': scores,
        'sortedScores': sortedScores,
      };
    } catch (e) {
      print("Error in _loadResultsData for room ${widget.roomCode}: $e");
      rethrow;
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.triviaName,
          style: GoogleFonts.robotoCondensed(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Final Results",
          style: GoogleFonts.robotoCondensed(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerPodium(
    List<MapEntry<String, int>> sortedScores,
    List<TriviaParticipant> participants,
  ) {
    final winnerEntry = sortedScores[0];
    final winner = participants.firstWhere(
      (p) => p.uid == winnerEntry.key,
      orElse: () => TriviaParticipant(
        uid: winnerEntry.key,
        username: 'Unknown User',
        isAdmin: false,
      ),
    );
    final winnerScore = winnerEntry.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.black.withOpacity(0.85),
          ),
          const SizedBox(height: 16),
          Text(
            "Winner!",
            style: GoogleFonts.robotoCondensed(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            winner.username,
            style: GoogleFonts.robotoCondensed(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "$winnerScore points",
            style: GoogleFonts.robotoCondensed(
              fontSize: 20,
              fontWeight: FontWeight.normal,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChart(
    List<MapEntry<String, int>> sortedScores,
    List<TriviaParticipant> participants,
    int totalQuestions,
  ) {
    final double maxPossibleScore = (totalQuestions * 10).toDouble();
    if (maxPossibleScore <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Score Distribution",
            style: GoogleFonts.robotoCondensed(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          ...sortedScores.map((entry) {
            final participant = participants.firstWhere(
              (p) => p.uid == entry.key,
              orElse: () => TriviaParticipant(
                uid: entry.key,
                username: 'Unknown User',
                isAdmin: false,
              ),
            );
            final percentage = (maxPossibleScore > 0 && entry.value >= 0)
                ? (entry.value / maxPossibleScore).clamp(0.0, 1.0)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          participant.username,
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "${entry.value} pts",
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Container(
                            width: constraints.maxWidth * percentage,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(
    List<MapEntry<String, int>> sortedScores,
    List<TriviaParticipant> participants,
    Map<String, int> scores,
    int totalQuestions,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Leaderboard",
            style: GoogleFonts.robotoCondensed(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          if (sortedScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  "No scores available.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            )
          else
            ...sortedScores.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final scoreEntry = entry.value;
              final participant = participants.firstWhere(
                (p) => p.uid == scoreEntry.key,
                orElse: () => TriviaParticipant(
                  uid: scoreEntry.key,
                  username: 'Unknown User',
                  isAdmin: false,
                ),
              );
              final isCurrentUser = participant.uid == _currentUserId;

              Color rankColor = Theme.of(
                context,
              ).colorScheme.secondary.withOpacity(0.7);
              Color rankTextColor = Colors.white;
              if (rank == 1) {
                rankColor = Colors.amber;
                rankTextColor = Colors.black;
              } else if (rank == 2) {
                rankColor = Colors.grey[400]!;
                rankTextColor = Colors.black87;
              } else if (rank == 3) {
                rankColor = const Color(0xFFCD7F32);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.tertiary.withOpacity(0.15)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrentUser
                      ? Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiary.withOpacity(0.8),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "$rank",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: rankTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participant.username,
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isCurrentUser)
                            Text(
                              "(You)",
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      "${scoreEntry.value} pts",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isDeleting
              ? null
              : () async {
                  if (_isAdmin) {
                    // Admin: Change status to waiting and navigate to TriviaScreen
                    setState(() => _isDeleting = true);
                    try {
                      await _firestoreService.updateRoomStatus(
                        roomCode: widget.roomCode,
                        status: 'waiting',
                      );

                      if (mounted) {
                        // Navigate back to TriviaScreen (where Join/Create is)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TriviaScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        _showError(
                          "Error updating room status: ${e.toString()}",
                        );
                        setState(() => _isDeleting = false);
                      }
                    }
                  } else {
                    // Participant: Simply navigate back to TriviaScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TriviaScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
          child: Container(
            height: 55,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: _isDeleting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Back to Trivia Home",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          },
          child: Text(
            "Back to Main Dashboard",
            style: GoogleFonts.robotoCondensed(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
