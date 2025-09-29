import 'package:cloud_firestore/cloud_firestore.dart';

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
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      phone: data['phone'], // Ajoutez cette ligne
      address: data['address'], // Ajoutez cette ligne
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
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
