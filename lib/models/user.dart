import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String role;
  final String name;
  final String email;

  AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
  });

  /// Factory depuis Firebase Auth (avec rôle par défaut = famille)
  factory AppUser.fromFirebaseUser(User firebaseUser, {String role = 'famille'}) {
    return AppUser(
      id: firebaseUser.uid,
      role: role,
      name: firebaseUser.displayName ?? 'Anonyme',
      email: firebaseUser.email ?? '',
    );
  }

  /// Factory depuis Firestore (collection "users")
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception("User document does not exist");
    }
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      role: data['role'] ?? 'famille',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }

  /// Conversion en Map (pour sauvegarde Firestore)
  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'email': email,
    };
  }
}
