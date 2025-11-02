import 'package:flutter/material.dart';
import 'package:quiz_app/screens/trivia_screen/trivia_screen.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:google_fonts/google_fonts.dart';
// Assuming you have these screen files
import 'package:quiz_app/screens/home_screen/home_screen.dart';
import 'package:quiz_app/screens/quiz_screen/upload_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [HomeScreen(), TriviaScreen(), UploadScreen()],
      ),
      bottomNavigationBar: StylishBottomBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        option: BubbleBarOptions(
          opacity: 1,
          iconSize: 28,
          bubbleFillStyle: BubbleFillStyle.fill,
          barStyle: BubbleBarStyle.horizontal,
        ),
        items: [
          BottomBarItem(
            backgroundColor: _selectedIndex == 0
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.secondary,
            selectedColor: _selectedIndex == 0
                ? Colors.black
                : Theme.of(context).colorScheme.secondary,
            icon: Icon(
              Icons.home_rounded,
              color: _selectedIndex == 0
                  ? Colors.black
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Home',
              style: GoogleFonts.robotoCondensed(
                color: _selectedIndex == 0
                    ? Colors.black
                    : Theme.of(context).colorScheme.secondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          BottomBarItem(
            backgroundColor: _selectedIndex == 1
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.secondary,
            selectedColor: _selectedIndex == 1
                ? Colors.black
                : Theme.of(context).colorScheme.secondary,
            icon: Icon(
              Icons.lightbulb_rounded,
              color: _selectedIndex == 1
                  ? Colors.black
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Trivia',
              style: GoogleFonts.robotoCondensed(
                color: _selectedIndex == 1
                    ? Colors.black
                    : Theme.of(context).colorScheme.secondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          BottomBarItem(
            backgroundColor: _selectedIndex == 2
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.secondary,
            selectedColor: _selectedIndex == 2
                ? Colors.black
                : Theme.of(context).colorScheme.secondary,
            icon: Icon(
              Icons.upload_file_rounded,
              color: _selectedIndex == 2
                  ? Colors.black
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Upload',
              style: GoogleFonts.robotoCondensed(
                color: _selectedIndex == 2
                    ? Colors.black
                    : Theme.of(context).colorScheme.secondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}
