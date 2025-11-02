import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz_app/components/difficulty_slider.dart';
import 'package:quiz_app/components/text_field.dart';
import 'package:quiz_app/models/trivia_room_model.dart';
import 'package:quiz_app/screens/trivia_screen/start_trivia_screen.dart';
import 'dart:math';
import 'package:quiz_app/services/firestore_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quiz_app/utils/constants.dart';

//
// --- PARENT WIDGET: CreateTrivia ---
//

class CreateTrivia extends StatefulWidget {
  const CreateTrivia({super.key});

  @override
  State<CreateTrivia> createState() => _CreateTriviaState();
}

class _CreateTriviaState extends State<CreateTrivia> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController triviaName;

  String difficulty = 'Medium';
  Set<String> topics = <String>{}; // This is the single source of truth
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    triviaName = TextEditingController();
  }

  @override
  void dispose() {
    triviaName.dispose();
    super.dispose();
  }

  Future<void> _handleCreateTrivia() async {
    final String? creatorUid = _auth.currentUser?.uid;

    if (creatorUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: You must be logged in to create a trivia."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // This will now have the correct topics from the child
    print("--- Topics at creation time: $topics ---");

    setState(() => _isLoading = true);

    try {
      String newRoomCode = generateRoomCode(6);

      final newTriviaRoom = TriviaRoom(
        name: triviaName.text.isNotEmpty ? triviaName.text : "My Trivia Room",
        categories: topics.isNotEmpty ? topics : {'General Knowledge'},
        difficulty: difficulty,
        roomCode: newRoomCode,
        creatorUid: creatorUid,
        participantUids: [creatorUid],
        status: 'waiting',
      );

      await _firestoreService.createTriviaRoom(
        triviaRoom: newTriviaRoom,
        creatorUid: creatorUid,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              StartTriviaScreen(userStatus: "Admin", triviaRoom: newTriviaRoom),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create trivia: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents keyboard overflow
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                QuizTextField(
                  isPassword: false,
                  controller: triviaName,
                  text: "name of trivia...",
                ),
                SizedBox(height: 32),
                Container(
                  height: 350,
                  padding: const EdgeInsets.all(12.5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  // --- FIX: Pass parent's state down to child ---
                  child: QuizTopicSelectorScreen(
                    selectedTopics: topics, // Pass the state
                    isTrivia: true, // Tell the child it's for trivia
                    onSelectionChanged: (newTopics) {
                      setState(() {
                        topics =
                            newTopics; // Update state from child's callback
                      });
                    },
                  ),
                ),
                SizedBox(height: 32),
                DifficultySlider(
                  initialDifficulty: difficulty,
                  onChanged: (String newDifficulty) {
                    setState(() {
                      difficulty = newDifficulty;
                    });
                  },
                ),
                SizedBox(height: 32),
                GestureDetector(
                  onTap: _isLoading ? null : _handleCreateTrivia,
                  child: Container(
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.7)
                          : Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Text(
                              "Create Trivia",
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String generateRoomCode(int length) {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final Random random = Random.secure();

  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

//
// --- CHILD WIDGET: QuizTopicSelectorScreen ---
//

class QuizTopicSelectorScreen extends StatefulWidget {
  const QuizTopicSelectorScreen({
    super.key,
    required this.isTrivia,
    required this.onSelectionChanged,
    required this.selectedTopics, // --- FIX: Added this parameter
  });

  final bool isTrivia;
  final void Function(Set<String> selectedTopics) onSelectionChanged;
  final Set<String> selectedTopics; // --- FIX: Added this parameter

  @override
  State<QuizTopicSelectorScreen> createState() =>
      _QuizTopicSelectorScreenState();
}

class _QuizTopicSelectorScreenState extends State<QuizTopicSelectorScreen> {
  late List<String> _allTopics;
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

  // --- FIX: Removed local state, now we use widget.selectedTopics ---
  // final Set<String> selectedTopics = <String>{};

  @override
  void initState() {
    super.initState();
    _allTopics = List.from(AppConstants.quizCategories);
    _filteredTopics = _popularTopics;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

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

  void _removeTopic(String topic) {
    // --- FIX: Create new set from widget state and pass up ---
    final newTopics = Set<String>.from(widget.selectedTopics);
    newTopics.remove(topic);
    widget.onSelectionChanged(newTopics); // Notify parent
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 12.5),

                    // --- FIX: Use widget.selectedTopics ---
                    if (widget.selectedTopics.isNotEmpty)
                      _buildSelectedTopicsDisplay(),
                    if (widget.selectedTopics.isNotEmpty)
                      const SizedBox(height: 12.5),

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
      ),
    );
  }

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
                  color: Theme.of(context).colorScheme.secondary,
                  icon: Icon(Icons.add_circle_outline_rounded),
                  onPressed: () {
                    setState(() {
                      if (_searchQuery.isNotEmpty &&
                          !_allTopics.contains(_searchQuery)) {
                        _allTopics.add(_searchQuery);
                        _filteredTopics.insert(0, _searchQuery);
                      }
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

  Widget _buildSelectedTopicsDisplay() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // --- FIX: Use widget.selectedTopics ---
        itemCount: widget.selectedTopics.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4.0),
        itemBuilder: (context, index) {
          // --- FIX: Use widget.selectedTopics ---
          final topic = widget.selectedTopics.elementAt(index);
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
          // --- FIX: Use widget.selectedTopics ---
          final isSelected = widget.selectedTopics.contains(topic);
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
              // --- FIX: Create new set and pass up ---
              final newTopics = Set<String>.from(widget.selectedTopics);
              if (selected) {
                newTopics.add(topic);
              } else {
                newTopics.remove(topic);
              }
              widget.onSelectionChanged(newTopics); // Notify parent
            },
          );
        }).toList(),
      ),
    );
  }
}
