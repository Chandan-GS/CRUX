import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for UpperCaseTextFormatter
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/components/text_field.dart'; // Assuming path is correct
import 'package:quiz_app/models/trivia_room_model.dart'; // Assuming path is correct
import 'package:quiz_app/screens/trivia_screen/start_trivia_screen.dart'; // Assuming path is correct
import 'package:quiz_app/services/firestore_service.dart'; // Assuming path is correct

class JoinTrivia extends StatefulWidget {
  const JoinTrivia({super.key});

  @override
  State<JoinTrivia> createState() => _JoinTriviaState();
}

class _JoinTriviaState extends State<JoinTrivia> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController _triviaCodeController;

  String? _joiningRoomId;
  bool _isJoiningByCode = false;

  @override
  void initState() {
    super.initState();
    _triviaCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _triviaCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinRoom(TriviaRoom room) async {
    // Check if room is joinable
    if (room.status != 'waiting') {
      _showError("This room is ${room.status} and cannot be joined.");
      return;
    }

    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      _showError("You must be logged in to join.");
      return;
    }

    // Check if room is full AND user is not already in it
    if (room.participantUids.length >= 5 &&
        !room.participantUids.contains(currentUserId)) {
      _showError("This room is full.");
      return;
    }

    setState(() {
      _joiningRoomId = room.roomCode;
    });

    try {
      // Step 1: Join the room in Firestore
      final success = await _firestoreService.joinTriviaRoom(
        room.roomCode,
        currentUserId,
      );

      if (success && mounted) {
        // Step 2: Fetch the UPDATED room data AFTER joining
        // We fetch again to ensure we have the absolute latest participant list
        final updatedRoom = await _firestoreService.getTriviaRoomByCode(
          room.roomCode,
        );
        if (updatedRoom == null) {
          throw Exception("Failed to fetch updated room data after joining.");
        }

        // Step 3: Navigate to the StartTriviaScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StartTriviaScreen(
              userStatus: updatedRoom.creatorUid == currentUserId
                  ? "Admin"
                  : "User",
              triviaRoom: updatedRoom, // Pass the latest room data
            ),
          ),
        );
      } else if (!success && mounted) {
        // Handle the specific case where join failed because it became full just now
        _showError("This room became full just before you joined.");
      }
    } catch (e) {
      if (mounted) _showError(e.toString()); // Show error if join/fetch failed
    } finally {
      if (mounted) {
        setState(() {
          _joiningRoomId = null; // Reset loading state regardless of outcome
        });
      }
    }
  }

  /// Handles joining via the text code input field
  void _handleJoinWithCode() async {
    final code = _triviaCodeController.text
        .trim()
        .toUpperCase(); // Ensure uppercase
    if (code.isEmpty) {
      _showError("Please enter a room code.");
      return;
    }

    setState(() {
      _isJoiningByCode = true;
    });

    try {
      // Fetch the room from Firestore using its code (FirestoreService handles case insensitivity)
      final room = await _firestoreService.getTriviaRoomByCode(code);

      if (room == null) {
        _showError("Room not found. Check the code and try again.");
      } else {
        // Check status before attempting to join
        if (room.status != 'waiting') {
          _showError("Room '$code' is ${room.status} and cannot be joined.");
        } else {
          // If room is found and waiting, call the standard join logic
          await _handleJoinRoom(room);
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningByCode = false;
        });
      }
    }
  }

  void _showError(String message) {
    // Ensure error messages are shown only if the widget is still mounted
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // "Online" count - TODO: This needs a real-time source (e.g., another Firestore listener)
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     Container(
          //       width: 10,
          //       height: 10,
          //       decoration: BoxDecoration(
          //         color: Colors.green,
          //         borderRadius: BorderRadius.circular(50),
          //       ),
          //     ),
          //     const SizedBox(width: 12.5),
          //     Text(
          //       "456 Online", // Static placeholder - replace with dynamic data later
          //       style: GoogleFonts.robotoCondensed(
          //         fontSize: 16,
          //         fontWeight: FontWeight.bold,
          //         color: Theme.of(context).colorScheme.secondary,
          //       ),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              Expanded(
                child: QuizTextField(
                  // Assuming QuizTextField is your custom TextField
                  controller: _triviaCodeController,
                  text: "enter trivia code...",
                  isPassword: false,
                ),
              ),
              const SizedBox(width: 10),
              // Show loading indicator or the join button
              _isJoiningByCode
                  ? const SizedBox(
                      width: 48, // Standard IconButton width
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ), // Slightly thicker
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: _handleJoinWithCode,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.all(
                          12,
                        ), // Ensure icon isn't too cramped
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 32),
          // Live list of available rooms
          Expanded(
            child: StreamBuilder<List<TriviaRoom>>(
              // Uses the stream that gets ALL rooms
              stream: _firestoreService.streamTriviaRooms(),
              builder: (context, snapshot) {
                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Handle error state
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Failed to load rooms: ${snapshot.error}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                // Handle no data state
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "No trivia rooms available. Create one!",
                      style: GoogleFonts.robotoCondensed(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Display list if data exists
                final rooms = snapshot.data!;
                // Optional: Sort rooms to show 'waiting' first
                rooms.sort((a, b) {
                  if (a.status == 'waiting' && b.status != 'waiting') return -1;
                  if (a.status != 'waiting' && b.status == 'waiting') return 1;
                  // Add secondary sort if desired (e.g., newest first)
                  // final dateA = a.createdAt?.millisecondsSinceEpoch ?? 0; // Requires createdAt in model
                  // final dateB = b.createdAt?.millisecondsSinceEpoch ?? 0;
                  // return dateB.compareTo(dateA);
                  return 0; // Default: no secondary sort
                });

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final bool isFull = room.participantUids.length >= 5;
                    final bool isLoading = _joiningRoomId == room.roomCode;
                    final bool canJoin =
                        room.status == 'waiting' || room.status == 'finished';

                    // Build the card for each room
                    return _TriviaRoomCard(
                      room: room,
                      isFull: isFull,
                      isLoading: isLoading,
                      canJoin: canJoin,
                      onTap: () =>
                          _handleJoinRoom(room), // Pass the join handler
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A stateless widget for displaying a single trivia room card.
class _TriviaRoomCard extends StatelessWidget {
  const _TriviaRoomCard({
    required this.room,
    required this.isFull,
    required this.isLoading,
    required this.canJoin,
    required this.onTap,
  });

  final TriviaRoom room;
  final bool isFull;
  final bool isLoading;
  final bool canJoin; // Indicates if status is 'waiting'
  final VoidCallback onTap;

  // Helper widget to display the room status or participant count
  Widget _buildStatusIndicator(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    switch (room.status) {
      case 'in-progress':
        icon = Icons.play_circle_fill_outlined;
        color = Colors.blueAccent;
        text = "In Progress";
        break;
      case 'finished':
        icon = Icons.check_circle_outline;
        color = Colors.grey[600]!; // Slightly darker grey
        text = "Finished";
        break;
      case 'waiting':
      default:
        // For 'waiting', show participant count / full status
        final bool isCurrentlyFull = room.participantUids.length >= 5;
        // Only show red if it's full AND still in 'waiting' state
        final bool showRed = isCurrentlyFull && room.status == 'waiting';
        return Text(
          "${room.participantUids.length} / 5",
          style: GoogleFonts.robotoCondensed(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: showRed ? Colors.redAccent : Colors.green, // Use accent red
          ),
        );
    }

    // Display icon and text for non-waiting states ('in-progress', 'finished')
    return Row(
      mainAxisSize: MainAxisSize.min, // Take minimum space needed
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.robotoCondensed(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine opacity based on joinability (only 'waiting' rooms are fully opaque)
    final double opacity = canJoin
        ? 1.0
        : 0.65; // Make non-joinable rooms dimmer

    return Container(
      margin: const EdgeInsets.only(bottom: 12.5),
      child: GestureDetector(
        // Disable onTap if loading OR if the room cannot be joined (not 'waiting')
        onTap: (isLoading || !canJoin) ? null : onTap,
        child: Opacity(
          // Apply opacity to visually dim non-joinable rooms
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary, // Card background
              borderRadius: BorderRadius.circular(17),
              // Add a subtle border for non-joinable rooms for visual distinction
              border: !canJoin
                  ? Border.all(color: Colors.grey.withOpacity(0.5), width: 1.0)
                  : null,
              boxShadow: canJoin
                  ? [
                      // Add a slight shadow only to joinable cards
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                  children: [
                    // Room Name (allow wrapping)
                    Expanded(
                      child: Text(
                        room.name,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 18, // Slightly larger font for name
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        maxLines: 2, // Allow name to wrap
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10), // Space before status/loader
                    // Loading indicator or Status/Participant Count
                    if (isLoading)
                      const SizedBox(
                        width: 24, // Keep consistent size
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          // Use secondary color for loader
                          color: Colors
                              .white, // Theme.of(context).colorScheme.secondary,
                        ),
                      )
                    else
                      _buildStatusIndicator(context), // Use the helper widget
                  ],
                ),
                const SizedBox(height: 12.5),
                // Categories List (horizontal scroll)
                SizedBox(
                  height: 35, // Consistent height for chips
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    // Handle empty categories list
                    children: room.categories.isEmpty
                        ? [_CategoryChip(category: 'General', context: context)]
                        : room.categories.map((category) {
                            return _CategoryChip(
                              category: category,
                              context: context,
                            );
                          }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extracted stateless widget for category chips.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.context});

  final String category;
  final BuildContext context; // Pass context if needed for theme access

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        // Use a slightly different background for chips
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(100), // Fully rounded
      ),
      child: Center(
        child: Text(
          category,
          style: GoogleFonts.robotoCondensed(
            fontWeight: FontWeight.w500, // Medium weight
            fontSize: 14,
            // Use a color that contrasts well with the chip background
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

/// A custom TextInputFormatter to automatically convert input to uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Return a new TextEditingValue with uppercase text
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection, // Keep cursor position
    );
  }
}
