import 'package:flutter/material.dart';
import 'package:quiz_app/services/gemini_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/models/trivia_room_model.dart';
import 'package:quiz_app/screens/dashboard_screen.dart';
import 'package:quiz_app/screens/trivia_screen/active_trivia_screen.dart';
import 'package:quiz_app/services/firestore_service.dart';

class StartTriviaScreen extends StatefulWidget {
  const StartTriviaScreen({
    super.key,
    required this.userStatus,
    required this.triviaRoom,
  });
  final String? userStatus;
  final TriviaRoom triviaRoom;

  @override
  State<StartTriviaScreen> createState() => _StartTriviaScreenState();
}

class _StartTriviaScreenState extends State<StartTriviaScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QuizApiService _apiService = QuizApiService();
  final _auth = FirebaseAuth.instance;
  String? _currentUserId;

  bool _isStartingGame = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  // --- Logic Methods ---

  Future<void> _handleStartGame(TriviaRoom room) async {
    if (_isStartingGame) return;

    try {
      setState(() => _isStartingGame = true);

      // Validate that we have categories and difficulty
      if (room.categories.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one category'),
            ),
          );
        }
        setState(() => _isStartingGame = false);
        return;
      }

      // 1. Generate questions using the API service
      // FIXED: Call generateTriviaQuiz instead of constructTriviaPrompt
      final questions = await _apiService.generateTriviaQuiz(
        categories: room.categories,
        difficulty: room.difficulty,
      );

      if (!mounted) return;

      // Validate that questions were generated
      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate questions')),
          );
        }
        setState(() => _isStartingGame = false);
        return;
      }

      // 2. Create the 'activeQuizzes' document
      await _firestoreService.createActiveQuiz(
        roomCode: room.roomCode,
        questions: questions,
      );

      // 3. Set the room status to 'in-progress'
      // This will trigger navigation for ALL players
      await _firestoreService.updateRoomStatus(
        roomCode: room.roomCode,
        status: 'in-progress',
      );

      // Navigation will happen automatically via the StreamBuilder
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error starting game: ${e.toString()}")),
      );

      setState(() {
        _isStartingGame = false;
      });
    }
  }

  Future<void> _leaveRoomLogic() async {
    if (_currentUserId == null) return;
    try {
      await _firestoreService.removeParticipant(
        widget.triviaRoom.roomCode,
        _currentUserId!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error leaving room: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _deleteRoomLogic() async {
    try {
      // First, delete the active quiz (if it exists)
      await _firestoreService.deleteActiveQuiz(
        roomCode: widget.triviaRoom.roomCode,
      );
      // Then, delete the trivia room lobby
      await _firestoreService.deleteTriviaRoom(
        roomCode: widget.triviaRoom.roomCode,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting room: ${e.toString()}")),
        );
      }
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit Room?"),
            content: const Text("Are you sure you want to leave this room?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Exit"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Room?"),
            content: const Text(
              "Are you sure you want to delete this room? This will kick all participants.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  // --- UI Building Methods ---

  Widget _buildTopicSelector(List<String> topics) {
    if (topics.isEmpty) {
      topics = ['General Knowledge'];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(topics.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  topics[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoCondensed(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPlayerDisplay() {
    return StreamBuilder<List<TriviaParticipant>>(
      stream: _firestoreService.streamTriviaParticipants(
        widget.triviaRoom.roomCode,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: Text("Error loading participants"),
            ),
          );
        }

        final participants = snapshot.data!;

        if (participants.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: Text("No one is here yet..."),
            ),
          );
        }

        return Center(
          child: Wrap(
            spacing: 50,
            runSpacing: 50,
            children: List.generate(participants.length, (index) {
              final participant = participants[index];
              final bool isAdmin = participant.isAdmin;

              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      participant.username,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isAdmin
                            ? Colors.white
                            : Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildRoomCode(String roomCode) {
    return Align(
      alignment: Alignment.bottomRight,
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: roomCode));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Room code copied!"),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roomCode,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.copy_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButtons(TriviaRoom room) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final bool confirmed = await _showDeleteDialog();
              if (confirmed) {
                await _deleteRoomLogic();
                _navigateToDashboard();
              }
            },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  "Delete Room",
                  style: GoogleFonts.robotoCondensed(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _isStartingGame ? null : () => _handleStartGame(room),
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: _isStartingGame
                    ? Colors.grey
                    : Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: _isStartingGame
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        "Start Trivia",
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
      ],
    );
  }

  Widget _buildParticipantButtons() {
    return GestureDetector(
      onTap: () async {
        final bool confirmed = await _showExitDialog();
        if (confirmed) {
          await _leaveRoomLogic();
          _navigateToDashboard();
        }
      },
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            "Exit Room",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TriviaRoom>(
      stream: _firestoreService.streamTriviaRoom(widget.triviaRoom.roomCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Error loading room or room deleted."),
                  TextButton(
                    onPressed: _navigateToDashboard,
                    child: const Text("Go Home"),
                  ),
                ],
              ),
            ),
          );
        }

        final triviaRoom = snapshot.data!;

        // --- SYNCHRONIZED NAVIGATION ---
        if (triviaRoom.status == 'in-progress') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ActiveTriviaScreen(roomCode: triviaRoom.roomCode),
                ),
              );
            }
          });
          return const Scaffold(body: Center(child: Text("Starting game...")));
        }
        // --- END OF NAVIGATION LOGIC ---

        final topicsList = triviaRoom.categories.toList();
        final bool isAdmin = widget.userStatus == "Admin";

        return WillPopScope(
          onWillPop: () async {
            if (isAdmin) {
              final bool confirmed = await _showDeleteDialog();
              if (confirmed) {
                await _deleteRoomLogic();
                _navigateToDashboard();
              }
              return false;
            } else {
              final bool confirmed = await _showExitDialog();
              if (confirmed) {
                await _leaveRoomLogic();
                _navigateToDashboard();
              }
              return false;
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      triviaRoom.name,
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildTopicSelector(topicsList),
                    const Spacer(),
                    _buildPlayerDisplay(),
                    const Spacer(),
                    _buildRoomCode(triviaRoom.roomCode),
                    const SizedBox(height: 20),
                    isAdmin
                        ? _buildAdminButtons(triviaRoom)
                        : _buildParticipantButtons(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
