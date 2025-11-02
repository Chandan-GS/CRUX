import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/screens/login_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _setupFirebaseMessaging() async {
    final fcm = FirebaseMessaging.instance;

    // 1. Request permission from the user
    await fcm.requestPermission(alert: true, sound: true, badge: true);

    // 2. Subscribe to the 'new_quiz' topic
    // Every device that runs this code will get the notification
    await fcm.subscribeToTopic('new_quiz');

    // 3. (Optional) Handle notifications when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        // You can show a local notification here if you want
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '  Welcome to',
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          'CRUX',
                          style: GoogleFonts.robotoCondensed(
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- WIDGET 2: The button aligned to the bottom ---
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                // Give the button some padding from the screen edges.
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 50),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () {
                      _setupFirebaseMessaging();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.robotoCondensed(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
