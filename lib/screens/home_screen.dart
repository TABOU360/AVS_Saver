import 'package:flutter/material.dart';
import '../widgets/futur_card.dart';
import '../core/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color : Colors.white,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AVS_Saver', style: TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Plateforme AVS • Familles • Coordination', style: TextStyle(color: Colors.greenAccent)),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                      if (appUser.role == 'admin') {
                        children: [
                        FuturCard(icon: Icons.admin_panel_settings, title: 'Admin', onTap: () => Navigator.pushNamed(context, AppRoutes.admin)),
                ],
                    } else if (appUser.role == 'avs') {

              }
                    children: [
                      FuturCard(icon: Icons.search, title: 'Trouver un·e AVS', onTap: () => Navigator.pushNamed(context, AppRoutes.browseAvs)),
                      FuturCard(icon: Icons.people, title: 'Bénéficiaires', onTap: () => Navigator.pushNamed(context, AppRoutes.beneficiaries)),
                      FuturCard(icon: Icons.calendar_month, title: 'Agenda', onTap: () => Navigator.pushNamed(context, AppRoutes.agenda)),
                      FuturCard(icon: Icons.chat, title: 'Messages', onTap: () => Navigator.pushNamed(context, AppRoutes.messages)),
                      FuturCard(icon: Icons.verified_user, title: 'Coordination', onTap: () => Navigator.pushNamed(context, AppRoutes.coordinator)),
                    ],
                  ),
                )
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
      ),
    );
  }
}
