// lib/screens/coordinator_screen.dart - Version corrigée complète
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../models/user.dart';
import '../models/mission.dart';
import '../core/app_routes.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class CoordinatorScreen extends StatefulWidget {
  const CoordinatorScreen({super.key});

  @override
  State<CoordinatorScreen> createState() => _CoordinatorScreenState();
}

class _CoordinatorScreenState extends State<CoordinatorScreen>
    with TickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final NavigationService _nav = NavigationService();

  AppUser? _user;
  bool _loading = true;
  List<Mission> _pendingMissions = [];
  List<Mission> _allMissions = [];
  Map<String, int> _stats = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCoordinatorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCoordinatorData() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser == null) {
        _nav.navigateToLogin();
        return;
      }

      // Vérifier le rôle
      if (currentUser.role != AppConstants.roleCoordinateur &&
          currentUser.role != AppConstants.roleAdmin) {
        _nav.showPermissionError();
        _nav.navigateBasedOnRole();
        return;
      }

      // Charger toutes les missions pour la coordination
      // En production, vous pourriez avoir une méthode spéciale pour les coordinateurs
      final allMissions = <Mission>[];
      // TODO: Implémenter la récupération de toutes les missions pour coordination

      final pendingMissions =
          allMissions.where((m) => m.status == MissionStatus.pending).toList();
      final stats = _calculateCoordinatorStats(allMissions);

      setState(() {
        _user = currentUser;
        _allMissions = allMissions;
        _pendingMissions = pendingMissions;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement données coordinateur: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Map<String, int> _calculateCoordinatorStats(List<Mission> missions) {
    return {
      'totalMissions': missions.length,
      'pendingMissions':
          missions.where((m) => m.status == MissionStatus.pending).length,
      'confirmedMissions':
          missions.where((m) => m.status == MissionStatus.confirmed).length,
      'completedMissions':
          missions.where((m) => m.status == MissionStatus.done).length,
      'todayMissions': missions.where((m) {
        final now = DateTime.now();
        return m.start.year == now.year &&
            m.start.month == now.month &&
            m.start.day == now.day;
      }).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coordination AVS'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'En attente'),
            Tab(icon: Icon(Icons.dashboard), text: 'Tableau de bord'),
            Tab(icon: Icon(Icons.analytics), text: 'Rapports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCoordinatorData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Mon profil'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title:
                      Text('Déconnexion', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingMissionsTab(),
                _buildDashboardTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildPendingMissionsTab() {
    return RefreshIndicator(
      onRefresh: _loadCoordinatorData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statistiques
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions,
                        color: Colors.orange.shade600, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_pendingMissions.length} demandes en attente',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Nécessitent votre validation',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Liste des missions en attente
            if (_pendingMissions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune demande en attente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toutes les demandes ont été traitées',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._pendingMissions
                  .map((mission) => _buildPendingMissionCard(mission)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingMissionCard(Mission mission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demande #${mission.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'EN ATTENTE',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Détails de la mission
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                    '${_formatDateTime(mission.start)} - ${_formatDateTime(mission.end)}'),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Famille: ${mission.familyId.substring(0, 8)}'),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Icon(Icons.medical_services,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('AVS: ${mission.avsId.substring(0, 8)}'),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _handleMissionAction(mission, 'reject'),
                  child: const Text(
                    'Refuser',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleMissionAction(mission, 'approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approuver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadCoordinatorData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        _user?.name.isNotEmpty == true
                            ? _user!.name[0].toUpperCase()
                            : 'C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour ${_user?.name ?? 'Coordinateur'} 👨‍💼',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gérez les demandes et supervisez les interventions',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistiques
            _buildCoordinatorStatsGrid(),

            const SizedBox(height: 24),

            // Actions rapides
            _buildCoordinatorQuickActions(),

            const SizedBox(height: 24),

            // Activité récente
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatorStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Total missions',
          value: '${_stats['totalMissions'] ?? 0}',
          icon: Icons.assignment,
          color: Colors.indigo,
        ),
        _buildStatCard(
          title: 'En attente',
          value: '${_stats['pendingMissions'] ?? 0}',
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Confirmées',
          value: '${_stats['confirmedMissions'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Aujourd\'hui',
          value: '${_stats['todayMissions'] ?? 0}',
          icon: Icons.today,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatorQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 4,
          children: [
            _buildQuickActionCard(
              title: 'Valider les demandes',
              subtitle: '${_pendingMissions.length} en attente',
              icon: Icons.pending_actions,
              color: Colors.orange.shade600,
              onTap: () => _tabController.animateTo(0),
            ),
            _buildQuickActionCard(
              title: 'Gérer les utilisateurs',
              subtitle: 'AVS et familles',
              icon: Icons.people_alt,
              color: Colors.blue.shade600,
              onTap: () {
                // Navigation vers gestion des utilisateurs
              },
            ),
            _buildQuickActionCard(
              title: 'Envoyer une notification',
              subtitle: 'Communiquer avec les utilisateurs',
              icon: Icons.notifications,
              color: Colors.green.shade600,
              onTap: _showSendNotificationDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentMissions = _allMissions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (recentMissions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune activité récente'),
            ),
          )
        else
          ...recentMissions.map((mission) => _buildActivityCard(mission)),
      ],
    );
  }

  Widget _buildActivityCard(Mission mission) {
    Color statusColor;
    String statusText;

    switch (mission.status) {
      case MissionStatus.pending:
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
      case MissionStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmée';
        break;
      case MissionStatus.done:
        statusColor = Colors.blue;
        statusText = 'Terminée';
        break;
      case MissionStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Annulée';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.assignment, color: statusColor),
        title: Text('Mission #${mission.id.substring(0, 8)}'),
        subtitle: Text(_formatDateTime(mission.start)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return RefreshIndicator(
      onRefresh: _loadCoordinatorData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapports et statistiques',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Graphiques et métriques
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé mensuel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMonthlyStatsGrid(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions de rapport
            _buildReportActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMonthlyStatCard('Missions créées', '${_allMissions.length}',
            Icons.add_circle_outline),
        _buildMonthlyStatCard('Missions validées',
            '${_stats['confirmedMissions'] ?? 0}', Icons.check_circle_outline),
        _buildMonthlyStatCard('Taux de validation', '85%', Icons.trending_up),
        _buildMonthlyStatCard('Satisfaction', '4.5/5', Icons.star_outline),
      ],
    );
  }

  Widget _buildMonthlyStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.indigo.shade600, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions de rapport',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Exporter rapport mensuel',
          icon: Icons.download,
          onPressed: _exportMonthlyReport,
        ),
        const SizedBox(height: 8),
        CustomButton(
          text: 'Générer rapport personnalisé',
          icon: Icons.analytics,
          onPressed: _showCustomReportDialog,
          backgroundColor: Colors.transparent,
          textColor: Colors.indigo.shade600,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _nav.navigateTo(AppRoutes.profile);
        break;
      case 'settings':
        // TODO: Implémenter les paramètres
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _handleMissionAction(Mission mission, String action) async {
    try {
      MissionStatus newStatus;
      String message;

      switch (action) {
        case 'approve':
          newStatus = MissionStatus.confirmed;
          message = 'Mission approuvée';
          break;
        case 'reject':
          newStatus = MissionStatus.cancelled;
          message = 'Mission rejetée';
          break;
        default:
          return;
      }

      await _db.updateMissionStatus(mission.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      _loadCoordinatorData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedAudience = 'all';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer une notification'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedAudience,
                decoration: const InputDecoration(
                  labelText: 'Destinataires',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('Tous les utilisateurs')),
                  DropdownMenuItem(value: 'avs', child: Text('Toutes les AVS')),
                  DropdownMenuItem(
                      value: 'families', child: Text('Toutes les familles')),
                ],
                onChanged: (value) => setState(() => selectedAudience = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter l'envoi de notification
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification envoyée')),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _exportMonthlyReport() {
    // TODO: Implémenter l'export du rapport
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapport en cours de génération...')),
    );
  }

  void _showCustomReportDialog() {
    // TODO: Implémenter le dialogue de rapport personnalisé
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonction en développement')),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr(e) de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              _nav.navigateToLogin();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
