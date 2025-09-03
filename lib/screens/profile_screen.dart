import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final firebaseUser = authService.value.currentUser;
  if (firebaseUser != null) {
  // Récupérez depuis Firestore si rôle stocké là
  final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
  final appUser = AppUser.fromFirestore(doc);
  // Affichez : Text('Bonjour, ${appUser.name} (${appUser.role})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text('Nom'), subtitle: Text('Famille T.')),
          ListTile(title: Text('Email'), subtitle: Text('famille@example.com')),
          ListTile(title: Text('Ville'), subtitle: Text('Yaoundé')),
        ],
      ),
    );
  }
}
