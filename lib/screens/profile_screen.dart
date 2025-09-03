import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<AppUser?> _loadUser() async {
    final firebaseUser = AuthService().currentUser;
    if (firebaseUser == null) return null;
    return await DatabaseService().getUserProfile(firebaseUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<AppUser?>(
        future: _loadUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            });
            return const SizedBox.shrink();
          }

          final user = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Nom'),
                subtitle: Text(user.name),
              ),
              ListTile(
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
              ListTile(
                title: const Text('Rôle'),
                subtitle: Text(user.role),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Modifier le profil',
                onPressed: () {
                  // TODO: Ajouter navigation vers un écran de modification
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Écran de modification non implémenté')),
                  );
                },
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Se déconnecter',
                onPressed: () async {
                  await AuthService().signOut();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
