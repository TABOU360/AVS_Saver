import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/futur_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<AppUser?> _loadUser() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return null;
    return await DatabaseService().getUserProfile(currentUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _loadUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          });
          return const SizedBox.shrink();
        }

        // Cartes disponibles pour tous
        final cards = <Widget>[
          FuturCard(
            icon: Icons.search,
            title: 'Trouver un·e AVS',
            onTap: () => Navigator.pushNamed(context, AppRoutes.browseAvs),
          ),
          FuturCard(
            icon: Icons.people,
            title: 'Bénéficiaires',
            onTap: () => Navigator.pushNamed(context, AppRoutes.beneficiaries),
          ),
          FuturCard(
            icon: Icons.calendar_month,
            title: 'Agenda',
            onTap: () => Navigator.pushNamed(context, AppRoutes.agenda),
          ),
          FuturCard(
            icon: Icons.chat,
            title: 'Messages',
            onTap: () => Navigator.pushNamed(context, AppRoutes.messages),
          ),
          FuturCard(
            icon: Icons.verified_user,
            title: 'Coordination',
            onTap: () => Navigator.pushNamed(context, AppRoutes.coordinator),
          ),
        ];

        // Cartes spécifiques selon rôle
        if (user.role == 'admin') {
          cards.add(
            FuturCard(
              icon: Icons.admin_panel_settings,
              title: 'Admin',
              onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
            ),
          );
        } else if (user.role == 'avs') {
          cards.add(
            FuturCard(
              icon: Icons.person,
              title: 'Mon Profil AVS',
              onTap: () => Navigator.pushNamed(context, AppRoutes.avsProfile),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVS_Saver',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bonjour, ${user.name}',
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: cards,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                  break;
                case 1:
                  Navigator.pushNamed(context, AppRoutes.profile);
                  break;
                case 2:
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Écran Paramètres non implémenté')),
                  );
                  break;
              }
            },
          ),
        );
      },
    );
  }
}
