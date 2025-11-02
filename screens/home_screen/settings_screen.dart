import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz_app/auth_gate.dart';
import 'package:quiz_app/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late Future<Map<String, dynamic>> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    if (_currentUser != null) {
      setState(() {
        _userProfileFuture = _firestoreService.getUserProfile(
          _currentUser!.uid,
        );
      });
    } else {
      _userProfileFuture = Future.error("User not logged in.");
    }
  }

  void _launchGrenckDevsURL() async {
    final Uri url = Uri.parse('https://grenckdevs.xyz');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open website: ${e.toString()}')),
        );
      }
    }
  }

  Future<String?> _showEditUsernameDialog(
    BuildContext context,
    String currentName,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            "Change Username",
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: GoogleFonts.robotoCondensed(
              color: Theme.of(context).colorScheme.secondary,
            ),
            decoration: InputDecoration(
              hintText: "Enter new username",
              hintStyle: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.robotoCondensed(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              onPressed: () {
                Navigator.of(context).pop(nameController.text.trim());
              },
              child: Text(
                "Save",
                style: GoogleFonts.robotoCondensed(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout?"),
        content: Text(
          "Are you sure you want to logout?",
          style: GoogleFonts.robotoCondensed(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Logout",
              style: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _handleDeleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text(
          "Are you sure you want to permanently delete your account? All your data (quizzes, scores) will be lost. This action cannot be undone.",
          style: GoogleFonts.robotoCondensed(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Delete Account",
              style: GoogleFonts.robotoCondensed(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentUser != null) {
      try {
        await _firestoreService.deleteUserData(_currentUser.uid);
        await _currentUser.delete();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthGate()),
            (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String message = "An error occurred.";
          if (e.code == 'requires-recent-login') {
            message =
                "This action is sensitive. Please logout and log back in to delete your account.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString()}',
                style: GoogleFonts.robotoCondensed(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.robotoCondensed(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || _currentUser == null) {
            return const Center(child: Text("Could not load user profile."));
          }

          final userData = snapshot.data!;
          final String username = userData['username'] ?? "No Username";

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Section Header
                      Text(
                        "ACCOUNT",
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Username Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Username",
                                    style: GoogleFonts.robotoCondensed(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    username,
                                    style: GoogleFonts.robotoCondensed(
                                      fontSize: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.7),
                              ),
                              onPressed: () async {
                                final newName = await _showEditUsernameDialog(
                                  context,
                                  username,
                                );
                                if (newName != null &&
                                    newName.isNotEmpty &&
                                    newName != username) {
                                  try {
                                    await _firestoreService.updateUsername(
                                      _currentUser.uid,
                                      newName,
                                    );
                                    _loadUserProfile();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                            style: GoogleFonts.robotoCondensed(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Email Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Email",
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentUser.email ?? 'No Email',
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // About Section Header
                      Text(
                        "ABOUT",
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // About Content
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromARGB(
                                          47,
                                          0,
                                          0,
                                          0,
                                        ),
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "lib/assets/CRUX_logo_icon.png",
                                    scale: 8,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Text(
                                  "Crux",
                                  style: GoogleFonts.robotoCondensed(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Crux is your ultimate quiz companion, designed to make learning fun and engaging. Create custom quizzes from your own content, challenge yourself with trivia, and track your progress over time.",
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 15,
                                height: 1.5,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Crafted by",
                                      style: GoogleFonts.robotoCondensed(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          "lib/assets/GD_logo.svg",
                                          width: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                        InkWell(
                                          onTap: _launchGrenckDevsURL,
                                          child: Text(
                                            " GrenckDevs",
                                            style: GoogleFonts.robotoCondensed(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue, // Link color
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Version",
                                      style: GoogleFonts.robotoCondensed(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "1.0.0",
                                      style: GoogleFonts.robotoCondensed(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Logout",
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                              SizedBox(width: 32),
                              Icon(Icons.logout_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: _handleDeleteAccount,
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Delete",
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 32),
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
