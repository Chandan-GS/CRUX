import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your other files
import 'package:quiz_app/screens/home_screen/user_quizes.dart';
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/services/firestore_service.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late final PageController _pageController;
  int _currentPage = 0;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Future to hold all quizzes fetched from Firestore
  late Future<List<Quiz>> _userQuizzesFuture;

  // 2. Set to store the IDs of favorited quizzes
  final Set<String> _favoriteQuizIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserQuizzes(); // Call the fetch method
  }

  // 3. Fetches quizzes for the current user
  void _loadUserQuizzes() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Set future to an error if user isn't logged in
      setState(() {
        _userQuizzesFuture = Future.error('User not authenticated.');
      });
    } else {
      // Fetch quizzes from Firestore
      setState(() {
        _userQuizzesFuture = _firestoreService.getUserQuizzes(uid);
      });
    }
  }

  // 4. Toggles a quiz's favorite status
  void _toggleFavorite(String quizId) {
    setState(() {
      if (_favoriteQuizIds.contains(quizId)) {
        _favoriteQuizIds.remove(quizId);
      } else {
        _favoriteQuizIds.add(quizId);
      }
    });
  }

  void _deleteQuiz(String quizId) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    try {
      await _firestoreService.deleteQuiz(uid, quizId);

      setState(() {
        _favoriteQuizIds.remove(quizId);
      });

      _loadUserQuizzes();
    } catch (e) {
      if (mounted) {}
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int page) {
    _pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.tertiary;
    final Color inactiveColor = Theme.of(context).scaffoldBackgroundColor;
    final Color activeTextColor = Colors.black;
    final Color inactiveTextColor = Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 30,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // --- This is your existing Tab UI, unchanged ---
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onTabTapped(0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 50,
                  decoration: BoxDecoration(
                    color: _currentPage == 0 ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      "All",
                      style: GoogleFonts.robotoCondensed(
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: _currentPage == 0
                            ? activeTextColor
                            : inactiveTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: GestureDetector(
                onTap: () => _onTabTapped(1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 50,
                  decoration: BoxDecoration(
                    color: _currentPage == 1 ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      "Favorites",
                      style: GoogleFonts.robotoCondensed(
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: _currentPage == 1
                            ? activeTextColor
                            : inactiveTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Expanded(
          child: FutureBuilder<List<Quiz>>(
            future: _userQuizzesFuture,
            builder: (context, snapshot) {
              // 1. Loading State
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Error State
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.robotoCondensed(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }

              // 3. No Data State
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No quizzes found.',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                );
              }

              // 4. Success State: We have data
              final List<Quiz> allQuizzes = snapshot.data!;

              // 5. Filter for the "Favorites" tab
              final List<Quiz> favoriteQuizzes = allQuizzes
                  .where((quiz) => _favoriteQuizIds.contains(quiz.quizId))
                  .toList();

              return PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  UserQuizes(
                    quizzes: allQuizzes,
                    favoriteQuizIds: _favoriteQuizIds,
                    onToggleFavorite: _toggleFavorite,
                    onDeleteQuiz: _deleteQuiz, // <-- PASS METHOD HERE
                  ),
                  UserQuizes(
                    quizzes: favoriteQuizzes,
                    favoriteQuizIds: _favoriteQuizIds,
                    onToggleFavorite: _toggleFavorite,
                    onDeleteQuiz: _deleteQuiz, // <-- PASS METHOD HERE
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
