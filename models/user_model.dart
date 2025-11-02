import 'package:uuid/uuid.dart';

class User {
  final String userId;
  final String name;
  final String email;

  User({String? userId, required this.name, required this.email})
    : userId = userId ?? const Uuid().v4();

  // Factory constructor to create a User from a Map (e.g., from Firestore)
  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }

  // Method to convert a User object to a Map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name, 'email': email};
  }
}
