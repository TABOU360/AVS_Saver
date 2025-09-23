import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../models/beneficiary.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  AppUser? _user;
  bool _loading = true;
  List<Beneficiary> _beneficiaries = [];
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser != null) {
        // Charger les bénéficiaires de la famille
        final beneficiaries = await _db.getUserBeneficiaries(currentUser.id);

        // Charger les réservations de la famille
        final bookings =
            await _db.getUserMissions(currentUser.id, currentUser.role);

        setState(() {
          _user = currentUser;
          _beneficiaries = beneficiaries;
          _bookings = bookings;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement données famille: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Famille - ${_user?.name ?? ''}'),
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
                    'Bonjour ${_user?.name ?? 'Famille'} 👋',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gérez vos bénéficiaires et réservations',
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
                  title: 'Bénéficiaires',
                  value: _beneficiaries.length.toString(),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Réservations',
                  value: _bookings.length.toString(),
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bénéficiaires
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vos bénéficiaires',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Navigation vers l'ajout de bénéficiaire
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_beneficiaries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun bénéficiaire enregistré'),
              ),
            )
          else
            ..._beneficiaries.take(3).map((beneficiary) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(beneficiary.fullName),
                    subtitle: Text(
                        '${beneficiary.age} ans - ${beneficiary.condition}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigation vers les détails du bénéficiaire
                    },
                  ),
                )),

          const SizedBox(height: 24),

          // Dernières réservations
          Text(
            'Vos dernières réservations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          if (_bookings.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune réservation en cours'),
              ),
            )
          else
            ..._bookings.take(3).map((booking) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text('Réservation #${booking.id.substring(0, 8)}'),
                    subtitle: Text('Statut: ${booking.status}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigation vers les détails de la réservation
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
