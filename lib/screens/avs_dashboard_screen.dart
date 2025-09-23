import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user.dart';

class AvsDashboardScreen extends StatefulWidget {
  const AvsDashboardScreen({super.key});

  @override
  State<AvsDashboardScreen> createState() => _AvsDashboardScreenState();
}

class _AvsDashboardScreenState extends State<AvsDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  AppUser? _user;
  bool _loading = true;
  List<dynamic> _missions = [];
  List<dynamic> _upcomingBookings = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser != null) {
        // Charger les missions de l'AVS
        final missions =
            await _db.getUserMissions(currentUser.id, currentUser.role);

        setState(() {
          _user = currentUser;
          _missions = missions;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement données AVS: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord AVS - ${_user?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de bienvenue
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ${_user?.name ?? 'AVS'} 👋',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voici votre activité aujourd\'hui',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Statistiques rapides
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Missions en cours',
                  value: _missions
                      .where((m) => m.status == 'confirmed')
                      .length
                      .toString(),
                  icon: Icons.work,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'À venir',
                  value: _missions
                      .where((m) => m.status == 'pending')
                      .length
                      .toString(),
                  icon: Icons.calendar_today,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Prochaines missions
          Text(
            'Vos prochaines missions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          if (_missions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune mission prévue pour le moment'),
              ),
            )
          else
            ..._missions.take(3).map((mission) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text('Mission #${mission.id.substring(0, 8)}'),
                    subtitle: Text('Statut: ${mission.status}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigation vers les détails de la mission
                    },
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
