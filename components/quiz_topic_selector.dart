import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/screens/home_screen/custom_quiz_input.dart';
import 'package:quiz_app/utils/constants.dart'; // Ensure this has your quizCategories list

class QuizTopicSelectorScreen extends StatefulWidget {
  const QuizTopicSelectorScreen({
    super.key,
    required this.isTrivia,
    required this.onSelectionChanged,
  });

  final bool isTrivia;
  final void Function(Set<String> selectedTopics) onSelectionChanged;

  @override
  State<QuizTopicSelectorScreen> createState() =>
      _QuizTopicSelectorScreenState();
}

class _QuizTopicSelectorScreenState extends State<QuizTopicSelectorScreen> {
  // Master list of all topics - never modified.
  final List<String> _allTopics = AppConstants.quizCategories;

  // A small, predefined list of popular topics to show initially.
  final List<String> _popularTopics = [
    'General Knowledge',
    'Science',
    'History',
    'Geography',
    'Film & TV',
    'Music',
    'Sports',
    'Art & Literature',
    'Technology',
    'Space & Astronomy',
  ];

  late List<String> _filteredTopics;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Set<String> selectedTopics = <String>{};

  @override
  void initState() {
    super.initState();
    _filteredTopics = _popularTopics;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// This method is called every time the user types in the search bar.
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      if (_searchQuery.isEmpty) {
        _filteredTopics = _popularTopics;
      } else {
        _filteredTopics = _allTopics
            .where(
              (topic) =>
                  topic.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }
    });
  }

  /// Method to remove a selected topic (called from both places)
  void _removeTopic(String topic) {
    setState(() {
      selectedTopics.remove(topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.5, right: 12.5, top: 12.5),
            child: Row(
              children: [
                Text(
                  "Customize Your Quiz",
                  style: GoogleFonts.robotoCondensed(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 12.5),
                selectedTopics.isNotEmpty && !widget.isTrivia
                    ? Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomQuizInput(categories: selectedTopics),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "Start",
                                    style: GoogleFonts.robotoCondensed(
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_double_arrow_right_rounded,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : Spacer(),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. The Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 12.5),

                  // 2. Selected Topics Display (Horizontal Scroll)
                  if (selectedTopics.isNotEmpty) _buildSelectedTopicsDisplay(),
                  if (selectedTopics.isNotEmpty) const SizedBox(height: 12.5),

                  // 3. The Scrollable Chip Display
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: _buildChipDisplay(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A helper widget to build the search bar UI.
  Widget _buildSearchBar() {
    return TextField(
      cursorColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
      controller: _searchController,
      style: GoogleFonts.robotoCondensed(
        color: Theme.of(context).colorScheme.secondary,
      ),
      decoration: InputDecoration(
        hintText: 'Search for a topic...',
        hintStyle: GoogleFonts.robotoCondensed(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(right: 5),
                child: IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  onPressed: () {
                    setState(() {
                      _filteredTopics.add(_searchController.text);
                    });
                  },
                ),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.5,
          ),
        ),
      ),
    );
  }

  /// A helper widget to build the selected topics display with horizontal scroll.
  Widget _buildSelectedTopicsDisplay() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: selectedTopics.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4.0),
        itemBuilder: (context, index) {
          final topic = selectedTopics.elementAt(index);
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topic,
                  style: GoogleFonts.robotoCondensed(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 6.0),
                GestureDetector(
                  onTap: () => _removeTopic(topic),
                  child: Icon(
                    Icons.cancel,
                    size: 18.0,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// A helper widget to build the chip display area.
  Widget _buildChipDisplay() {
    if (_filteredTopics.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.5),
          child: Text(
            'No topics found for "$_searchQuery"',
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.5),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _filteredTopics.map((topic) {
          final isSelected = selectedTopics.contains(topic);
          return FilterChip(
            label: Text(
              topic,
              style: GoogleFonts.robotoCondensed(
                color: isSelected
                    ? Colors.black
                    : Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: Theme.of(context).colorScheme.tertiary,
            shape: StadiumBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2.5,
              ),
            ),
            checkmarkColor: Colors.black,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  selectedTopics.add(topic);
                } else {
                  selectedTopics.remove(topic);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
