import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class TriviaParticipant {
  final String uid;
  final String username;
  final bool isAdmin;

  const TriviaParticipant({
    required this.uid,
    required this.username,
    required this.isAdmin,
  });

  TriviaParticipant copyWith({String? uid, String? username, bool? isAdmin}) {
    return TriviaParticipant(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriviaParticipant &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

@immutable
class TriviaRoom {
  final String name;
  final Set<String> categories;
  final String difficulty;
  final String roomCode;
  final String status;
  final String creatorUid;

  /// List of UIDs. This IS stored in Firestore.
  final List<String> participantUids;

  // --- 2. ADD THIS UI-ONLY PROPERTY ---
  /// A list of hydrated participant models.
  /// This is for UI use and is NOT stored in Firestore.
  /// It must be populated manually *after* fetching the room.
  final List<TriviaParticipant> participants;

  /// Main constructor for creating a new room.
  const TriviaRoom({
    required this.name,
    required this.categories,
    required this.difficulty,
    required this.roomCode,
    this.participantUids = const [],
    this.status = 'waiting',
    this.creatorUid = '',
    this.participants = const [], // <-- 3. Add default value
  });

  /// Converts this [TriviaRoom] instance to a JSON Map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'categories': categories.toList(), // Convert Set to List for Firestore
      'difficulty': difficulty,
      'roomCode': roomCode,
      'participantUids': participantUids,
      'status': status,
      'creatorUid': creatorUid,
      // Notice 'participants' is NOT saved to Firestore
    };
  }

  factory TriviaRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final categoriesList = data['categories'] as List<dynamic>?;
    final categoriesSet =
        categoriesList?.map((e) => e.toString()).toSet() ?? <String>{};
    final participantsList = data['participantUids'] as List<dynamic>?;
    final participantsUids =
        participantsList?.map((e) => e.toString()).toList() ?? <String>[];

    return TriviaRoom(
      name: data['name'] ?? 'Untitled Trivia',
      categories: categoriesSet,
      difficulty: data['difficulty'] ?? 'Medium',
      roomCode: data['roomCode'] ?? '',
      participantUids: participantsUids,
      status: data['status'] ?? 'unknown',
      creatorUid: data['creatorUid'] ?? '',
    );
  }

  /// ADD THIS METHOD - Creates TriviaRoom from a Map (used by getTriviaRoom)
  factory TriviaRoom.fromMap(Map<String, dynamic> data) {
    final categoriesList = data['categories'] as List<dynamic>?;
    final categoriesSet =
        categoriesList?.map((e) => e.toString()).toSet() ?? <String>{};
    final participantsList = data['participantUids'] as List<dynamic>?;
    final participantsUids =
        participantsList?.map((e) => e.toString()).toList() ?? <String>[];

    return TriviaRoom(
      name: data['name'] ?? 'Untitled Trivia',
      categories: categoriesSet,
      difficulty: data['difficulty'] ?? 'Medium',
      roomCode: data['roomCode'] ?? '',
      participantUids: participantsUids,
      status: data['status'] ?? 'unknown',
      creatorUid: data['creatorUid'] ?? '',
    );
  }

  /// Creates a new instance of [TriviaRoom] with updated values.
  TriviaRoom copyWith({
    String? name,
    Set<String>? categories,
    String? difficulty,
    String? roomCode,
    List<String>? participantUids,
    String? status,
    String? creatorUid,
    List<TriviaParticipant>? participants, // <-- 4. Add to copyWith
  }) {
    return TriviaRoom(
      name: name ?? this.name,
      categories: categories ?? this.categories,
      difficulty: difficulty ?? this.difficulty,
      roomCode: roomCode ?? this.roomCode,
      participantUids: participantUids ?? this.participantUids,
      status: status ?? this.status,
      creatorUid: creatorUid ?? this.creatorUid,
      participants: participants ?? this.participants, // <-- 5. Use in copyWith
    );
  }
}
