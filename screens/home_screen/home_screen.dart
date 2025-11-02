import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quiz_app/components/quiz_topic_selector.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/models/quiz_score_model.dart';
import 'package:quiz_app/screens/home_screen/home_dashboard.dart';
import 'package:quiz_app/screens/home_screen/quiz_of_day_quiz_screen.dart';
import 'package:quiz_app/screens/home_screen/settings_screen.dart';
import 'package:quiz_app/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late Future<Map<String, dynamic>> _loadDataFuture;
  late String _todayDateString;

  @override
  void initState() {
    super.initState();
    _todayDateString = _getTodayDateString();

    _loadDataFuture = _loadInitialData();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    final String? currentUserId = _firebaseAuth.currentUser?.uid;
    final quizDataFuture = _firestoreService.getQuizOfTheDay(_todayDateString);

    // Check if the user has played
    final hasPlayedFuture = currentUserId != null
        ? _firestoreService.hasUserPlayedToday(_todayDateString, currentUserId)
        : Future.value(false); // Default to false if no user

    // Wait for both to complete
    final results = await Future.wait([quizDataFuture, hasPlayedFuture]);

    return {
      'quizData': results[0] as Map<String, dynamic>,
      'hasPlayed': results[1] as bool, // Store the play status
    };
  }

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Widget _getRankWidget(int rank, BuildContext context, {double size = 20}) {
    IconData icon = Icons.emoji_events;
    Color color;

    switch (rank) {
      case 1:
        color = const Color.fromARGB(255, 255, 200, 0);
        break;
      case 2:
        color = const Color.fromARGB(255, 163, 163, 163);
        break;
      case 3:
        color = const Color(0xFFCD7F32);
        break;
      default:
        return Text(
          '#$rank',
          style: GoogleFonts.robotoCondensed(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ),
        );
    }
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: size + 4, // Make icon slightly larger than text
        ),
      ),
    );
  }

  void _showLeaderboardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StreamBuilder<List<QuizScore>>(
              stream: _firestoreService.getAllQuizOfTheDayScores(
                _todayDateString,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No scores submitted yet.'));
                }

                final scores = snapshot.data!;

                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Text(
                      "Today's Leaderboard",
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: scores.length,
                        itemBuilder: (context, index) {
                          final score = scores[index];
                          final rank = index + 1;
                          // 4. UPDATED: Pass rank to build tile
                          return _buildRankTile(score, rank);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // 5. UPDATED: _buildRankTile now uses the icon widget
  Widget _buildRankTile(QuizScore score, int rank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Use the rank widget instead of Text('#$rank')
          _getRankWidget(rank, context, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              score.username,
              style: GoogleFonts.robotoCondensed(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${score.score} pts',
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

  // 6. UPDATED: This widget now builds based on the combined future
  Widget _buildQuizOfTheDayCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadDataFuture, // Use the new future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            // ... (error UI) ...
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Error loading quiz: ${snapshot.error}',
                style: GoogleFonts.robotoCondensed(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No quiz data found.'));
        }

        // Extract data from the new map
        final quizData = snapshot.data!['quizData'] as Map<String, dynamic>;
        final bool hasPlayed = snapshot.data!['hasPlayed'] as bool;

        final String quizTitle = quizData['quizTitle'];
        final List<Question> questions = quizData['questions'];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Quiz of the Day",
                      style: GoogleFonts.robotoCondensed(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      quizTitle,
                      style: GoogleFonts.robotoCondensed(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // 7. UPDATED: The "Start" button logic
                    GestureDetector(
                      // Disable onTap if user has played
                      onTap: hasPlayed
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizOfDayScreen(
                                    questions: questions,
                                    quizTitle: quizTitle,
                                    difficulty: 'Medium',
                                    duration: '10 min',
                                    // 8. UPDATED: onQuizCompleted is now async
                                    onQuizCompleted: (int score) async {
                                      final String? currentUserId =
                                          _firebaseAuth.currentUser?.uid;

                                      if (currentUserId != null) {
                                        // Fetch profile from Firestore
                                        final userProfile =
                                            await _firestoreService
                                                .getUserProfile(currentUserId);
                                        final String username =
                                            userProfile['username'];

                                        // Submit score with correct username
                                        await _firestoreService
                                            .submitQuizOfTheDayScore(
                                              dateString: _todayDateString,
                                              userId: currentUserId,
                                              username: username,
                                              score: score,
                                            );

                                        // Refresh the card to disable the button
                                        setState(() {
                                          _loadDataFuture = _loadInitialData();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12.5),
                        height: 50,
                        decoration: BoxDecoration(
                          // Grey out button if user has played
                          color: hasPlayed
                              ? Colors.grey[600]
                              : Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            // Change text if user has played
                            hasPlayed ? "Played" : "Start",
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 18,
                              color: hasPlayed ? Colors.white70 : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildLeaderboardCard(), // Leaderboard widget
              ),
            ],
          ),
        );
      },
    );
  }

  // 9. UPDATED: Leaderboard card now uses icons
  Widget _buildLeaderboardCard() {
    return GestureDetector(
      onTap: _showLeaderboardModal,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: StreamBuilder<List<QuizScore>>(
            stream: _firestoreService.getQuizOfTheDayLeaderboard(
              _todayDateString,
              limit: 3,
            ),
            builder: (context, snapshot) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Leaderboard",
                    style: GoogleFonts.robotoCondensed(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Build UI based on snapshot
                  if (snapshot.hasData && snapshot.data!.isNotEmpty)
                    // If we have data, build the list of winners
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data!.asMap().entries.map((entry) {
                        int rank = entry.key + 1;
                        String username = entry.value.username;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              _getRankWidget(rank, context, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  username,
                                  style: GoogleFonts.robotoCondensed(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else if (snapshot.hasData)
                    // We have data, but it's an empty list
                    Text(
                      "Be the first to play!",
                      style: GoogleFonts.robotoCondensed(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    )
                  else if (snapshot.hasError)
                    // An error occurred
                    Text(
                      "Coming Soon",
                      style: GoogleFonts.robotoCondensed(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    )
                  else
                    // Still loading
                    Text(
                      "Loading...",
                      style: GoogleFonts.robotoCondensed(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.leaderboard_rounded,
                        size: 30,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              size: 30,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "CRUX",
          style: GoogleFonts.robotoCondensed(
            fontSize: 30,
            letterSpacing: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: PageView(
            scrollDirection: Axis.vertical,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQuizOfTheDayCard(), // Use the new widget
                              const SizedBox(height: 12.5),
                              QuizTopicSelectorScreen(
                                isTrivia: false,
                                onSelectionChanged: (selectedTopics) => {},
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 30,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              Text(
                                "My Quizzes",
                                style: GoogleFonts.robotoCondensed(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const HomeDashboard(), // Kept your original second page
            ],
          ),
        ),
      ),
    );
  }
}
