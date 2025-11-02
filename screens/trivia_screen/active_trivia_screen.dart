import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/components/quiz_ui_widget.dart';
import 'package:quiz_app/models/active_quiz_model.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/models/trivia_room_model.dart';
import 'package:quiz_app/screens/trivia_screen/trivia_result_screen.dart';
import 'package:quiz_app/services/firestore_service.dart';
import 'dart:async';

class ActiveTriviaScreen extends StatefulWidget {
  final String roomCode;

  const ActiveTriviaScreen({super.key, required this.roomCode});

  @override
  State<ActiveTriviaScreen> createState() => _ActiveTriviaScreenState();
}

class _ActiveTriviaScreenState extends State<ActiveTriviaScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Use ValueNotifier for selected option to avoid rebuilding everything
  final ValueNotifier<String?> _selectedOptionNotifier = ValueNotifier(null);
  bool _isSubmitting = false;
  int _previousQuestionIndex = -1;

  // Timer State
  Timer? _questionTimer;
  late AnimationController _timerAnimationController;
  final int _timerDurationSeconds = 10;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timerDurationSeconds),
    );
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _timerAnimationController.dispose();
    _selectedOptionNotifier.dispose();
    super.dispose();
  }

  void _startQuestionTimer(
    ActiveQuiz activeQuiz,
    int currentQuestionIndex,
    bool isAdmin,
  ) {
    if (_isTimerRunning || !mounted) return;

    setState(() {
      _isTimerRunning = true;
    });

    _timerAnimationController.forward(from: 0.0);

    _questionTimer?.cancel();
    _questionTimer = Timer(Duration(seconds: _timerDurationSeconds), () {
      if (!mounted) return;

      _isTimerRunning = false;

      if (isAdmin) {
        _moveToNextQuestion(activeQuiz, currentQuestionIndex);
      }
    });
  }

  Future<void> _moveToNextQuestion(
    ActiveQuiz activeQuiz,
    int currentQuestionIndex,
  ) async {
    final String creatorUid = await _firestoreService.getTriviaRoomCreator(
      widget.roomCode,
    );
    if (_currentUserId != creatorUid || !mounted) return;

    _questionTimer?.cancel();
    _timerAnimationController.stop();
    _isTimerRunning = false;

    try {
      if (currentQuestionIndex >= activeQuiz.questions.length - 1) {
        await _firestoreService.updateRoomStatus(
          roomCode: widget.roomCode,
          status: 'finished',
        );
      } else {
        await _firestoreService.moveToNextQuestion(roomCode: widget.roomCode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error advancing question: $e")));
      }
    }
  }

  Future<void> _handleSubmitAnswer(int currentQuestionIndex) async {
    if (_selectedOptionNotifier.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an option first!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestoreService.submitTriviaAnswer(
        roomCode: widget.roomCode,
        questionIndex: currentQuestionIndex,
        answer: _selectedOptionNotifier.value!,
        uid: _currentUserId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit: $e"),
            backgroundColor: Colors.red,
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<TriviaRoom>(
        stream: _firestoreService.streamTriviaRoom(widget.roomCode),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (roomSnapshot.hasError) {
            return Center(
              child: Text("Error loading room: ${roomSnapshot.error}"),
            );
          }
          if (!roomSnapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pop();
            });
            return const Center(child: Text("Room not found or deleted."));
          }

          final triviaRoom = roomSnapshot.data!;
          final bool isAdmin = triviaRoom.creatorUid == _currentUserId;

          if (triviaRoom.status == 'finished') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _questionTimer?.cancel();
                _timerAnimationController.stop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => TriviaResultScreen(
                      roomCode: widget.roomCode,
                      triviaName: triviaRoom.name,
                    ),
                  ),
                );
              }
            });
            return const Scaffold(
              body: Center(child: Text("Finishing game...")),
            );
          }

          if (triviaRoom.status != 'in-progress') {
            return Scaffold(
              body: Center(
                child: Text(
                  "Waiting for game to start... Status: ${triviaRoom.status}",
                ),
              ),
            );
          }

          return StreamBuilder<ActiveQuiz>(
            stream: _firestoreService.streamActiveQuiz(widget.roomCode),
            builder: (context, quizSnapshot) {
              if (quizSnapshot.connectionState == ConnectionState.waiting &&
                  !quizSnapshot.hasData) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Loading questions..."),
                    ],
                  ),
                );
              }
              if (quizSnapshot.hasError) {
                return Center(
                  child: Text("Error loading quiz data: ${quizSnapshot.error}"),
                );
              }
              if (!quizSnapshot.hasData) {
                return const Center(child: Text("Waiting for quiz data..."));
              }

              final activeQuiz = quizSnapshot.data!;
              final int qIndex = activeQuiz.currentQuestionIndex;

              if (activeQuiz.questions.isEmpty) {
                return const Center(child: Text("Waiting for questions..."));
              }
              if (qIndex < 0 || qIndex >= activeQuiz.questions.length) {
                return const Center(
                  child: Text("Quiz appears to be over. Waiting..."),
                );
              }

              final Question currentQuestion = activeQuiz.questions[qIndex];
              final bool hasAnswered = activeQuiz.hasUserAnswered(
                _currentUserId,
                qIndex,
              );

              // Handle question change
              if (_previousQuestionIndex != qIndex) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _questionTimer?.cancel();
                    _timerAnimationController.reset();
                    _selectedOptionNotifier.value = null;
                    setState(() {
                      _previousQuestionIndex = qIndex;
                      _isSubmitting = false;
                      _isTimerRunning = false;
                    });
                  }
                });
              }

              // Check for timer start
              final Map<String, dynamic>? currentQuestionAnswers =
                  activeQuiz.answers.containsKey(qIndex.toString())
                  ? activeQuiz.answers[qIndex.toString()]
                        as Map<String, dynamic>?
                  : null;
              final bool someoneAnswered =
                  currentQuestionAnswers != null &&
                  currentQuestionAnswers.isNotEmpty;

              if (someoneAnswered &&
                  !_isTimerRunning &&
                  _previousQuestionIndex == qIndex) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _startQuestionTimer(activeQuiz, qIndex, isAdmin);
                  }
                });
              }

              return SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _QuestionHeader(
                        currentIndex: qIndex,
                        totalQuestions: activeQuiz.questions.length,
                        timerController: _timerAnimationController,
                        isTimerRunning: _isTimerRunning,
                        timerDuration: _timerDurationSeconds,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _QuizContent(
                          currentQuestion: currentQuestion,
                          selectedOptionNotifier: _selectedOptionNotifier,
                          hasAnswered: hasAnswered,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _SubmitButton(
                        hasAnswered: hasAnswered,
                        isSubmitting: _isSubmitting,
                        isTimerRunning: _isTimerRunning,
                        timerController: _timerAnimationController,
                        timerDuration: _timerDurationSeconds,
                        onTap: () => _handleSubmitAnswer(qIndex),
                      ),
                    ),
                    _ParticipantList(
                      roomCode: widget.roomCode,
                      activeQuiz: activeQuiz,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Question header with timer
class _QuestionHeader extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final AnimationController timerController;
  final bool isTimerRunning;
  final int timerDuration;

  const _QuestionHeader({
    required this.currentIndex,
    required this.totalQuestions,
    required this.timerController,
    required this.isTimerRunning,
    required this.timerDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Question ${currentIndex + 1} of $totalQuestions",
            style: GoogleFonts.robotoCondensed(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          AnimatedBuilder(
            animation: timerController,
            builder: (context, child) {
              final remaining = timerDuration * (1.0 - timerController.value);
              if (!isTimerRunning || remaining <= 0) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "${remaining.ceil()}s",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Quiz content with ValueNotifier to prevent unnecessary rebuilds
class _QuizContent extends StatelessWidget {
  final Question currentQuestion;
  final ValueNotifier<String?> selectedOptionNotifier;
  final bool hasAnswered;

  const _QuizContent({
    required this.currentQuestion,
    required this.selectedOptionNotifier,
    required this.hasAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: AbsorbPointer(
        absorbing: hasAnswered,
        child: Opacity(
          opacity: hasAnswered ? 0.6 : 1.0,
          child: ValueListenableBuilder<String?>(
            valueListenable: selectedOptionNotifier,
            builder: (context, selectedOption, child) {
              return QuizUIWidget(
                questionText: currentQuestion.questionText,
                options: currentQuestion.options,
                selectedOption: selectedOption,
                onOptionSelected: (option) {
                  if (!hasAnswered) {
                    selectedOptionNotifier.value = option;
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Submit button - only rebuilds when state changes
class _SubmitButton extends StatelessWidget {
  final bool hasAnswered;
  final bool isSubmitting;
  final bool isTimerRunning;
  final AnimationController timerController;
  final int timerDuration;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.hasAnswered,
    required this.isSubmitting,
    required this.isTimerRunning,
    required this.timerController,
    required this.timerDuration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hasAnswered) {
      return Container(
        height: 55,
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16, bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                "Submitted",
                style: GoogleFonts.robotoCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: (isSubmitting || hasAnswered) ? null : onTap,
      child: Container(
        height: 55,
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 2.5,
          ),
        ),
        child: Stack(
          children: [
            // Animated fill background
            if (isTimerRunning)
              AnimatedBuilder(
                animation: timerController,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: timerController.value,
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.tertiary.withOpacity(0.6),
                                Theme.of(context).colorScheme.tertiary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Button text
            Center(
              child: isSubmitting
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    )
                  : AnimatedBuilder(
                      animation: timerController,
                      builder: (context, child) {
                        final remaining =
                            timerDuration * (1.0 - timerController.value);
                        return Text(
                          isTimerRunning && remaining > 0
                              ? "Submit (${remaining.ceil()})"
                              : "Submit",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Participant list with improved styling
class _ParticipantList extends StatelessWidget {
  final String roomCode;
  final ActiveQuiz activeQuiz;

  const _ParticipantList({required this.roomCode, required this.activeQuiz});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TriviaParticipant>>(
      stream: FirestoreService().streamTriviaParticipants(roomCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text("Error loading participants")),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text("Waiting for participants...")),
          );
        }

        final participants = snapshot.data!;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: participants.map((participant) {
              final bool hasAnswered = activeQuiz.hasUserAnswered(
                participant.uid,
                activeQuiz.currentQuestionIndex,
              );

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasAnswered
                      ? Colors.green
                      : Theme.of(context).colorScheme.secondary,
                  boxShadow: [
                    BoxShadow(
                      color: hasAnswered
                          ? Colors.green.withOpacity(0.4)
                          : Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.2),
                      blurRadius: hasAnswered ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      participant.username.isNotEmpty
                          ? participant.username
                          : "?",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
