import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone; // Ajoutez cette ligne
  final String? address; // Ajoutez cette ligne
  final DateTime? createdAt; // Ajoutez cette ligne

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone, // Ajoutez ce paramètre
    this.address, // Ajoutez ce paramètre
    this.createdAt, // Ajoutez ce paramètre
  });

  // Méthode fromMap mise à jour
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: AppConstants.normalizeRole(map['role'] as String? ?? ''), // <- normalisation à la lecture
      phone: map['phone'], // Ajoutez cette ligne
      address: map['address'], // Ajoutez cette ligne
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null, // Ajoutez cette ligne
    );
  }

  // Méthode toMap mise à jour
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone, // Ajoutez cette ligne
      'address': address, // Ajoutez cette ligne
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(), // Ajoutez cette ligne
    };
  }
}
