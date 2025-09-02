import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
