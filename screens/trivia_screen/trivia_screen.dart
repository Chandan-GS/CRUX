import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/screens/trivia_screen/create_trivia.dart';
import 'package:quiz_app/screens/trivia_screen/join_trivia.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    // 3. Dispose the controller to prevent memory leaks.
    _pageController.dispose();
    super.dispose();
  }

  // Helper method to handle tab taps.
  void _onTabTapped(int page) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 100),
      curve: Curves.bounceIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.tertiary;
    final Color inactiveColor = Theme.of(context).colorScheme.secondary;
    final Color activeTextColor = Colors.black;
    final Color inactiveTextColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTapped(0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 50,
                        decoration: BoxDecoration(
                          color: _currentPage == 0
                              ? activeColor
                              : inactiveColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            "Join",
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
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTapped(1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: 50,
                        decoration: BoxDecoration(
                          color: _currentPage == 1
                              ? activeColor
                              : inactiveColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            "Create",
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,

                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: const [JoinTrivia(), CreateTrivia()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
