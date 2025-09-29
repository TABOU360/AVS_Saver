import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../models/user.dart';
import '../core/app_routes.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final NavigationService _nav = NavigationService();

  AppUser? _user;
  bool _loading = true;
  Map<String, dynamic> _systemStats = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser == null) {
        _nav.navigateToLogin();
        return;
      }

      // Vérifier le rôle admin
      if (currentUser.role != AppConstants.roleAdmin) {
        _nav.showPermissionError();
        _nav.navigateBasedOnRole();
        return;
      }

      // Charger les statistiques système
      // TODO: Implémenter la récupération des stats système
      final systemStats = {
        'totalUsers': 150,
        'totalAvs': 45,
        'totalFamilies': 95,
        'totalCoordinators': 8,
        'totalMissions': 342,
        'activeMissions': 28,
      };

      setState(() {
        _user = currentUser;
        _systemStats = systemStats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement données admin: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tableau de bord'),
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.verified_user), text: 'Vérifications'),
            Tab(icon: Icon(Icons.settings), text: 'Système'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
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
                _buildDashboardTab(),
                _buildUsersTab(),
                _buildVerificationTab(),
                _buildSystemTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue admin
            Card(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: Colors.red.shade600, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue ${_user?.name ?? 'Admin'} 👨‍💻',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Administration du système AVS Saver',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistiques système
            _buildSystemStatsGrid(),

            const SizedBox(height: 24),

            // Actions admin rapides
            _buildAdminQuickActions(),

            const SizedBox(height: 24),

            // Alertes système
            _buildSystemAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Total utilisateurs',
          value: '${_systemStats['totalUsers'] ?? 0}',
          icon: Icons.people,
          color: Colors.red,
        ),
        _buildStatCard(
          title: 'AVS actives',
          value: '${_systemStats['totalAvs'] ?? 0}',
          icon: Icons.medical_services,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Familles',
          value: '${_systemStats['totalFamilies'] ?? 0}',
          icon: Icons.family_restroom,
          color: Colors.purple,
        ),
        _buildStatCard(
          title: 'Missions actives',
          value: '${_systemStats['activeMissions'] ?? 0}',
          icon: Icons.assignment,
          color: Colors.green,
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

  Widget _buildAdminQuickActions() {
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
              title: 'Gérer les utilisateurs',
              subtitle: 'Voir, modifier, désactiver',
              icon: Icons.people_alt,
              color: Colors.blue.shade600,
              onTap: () => _tabController.animateTo(1),
            ),
            _buildQuickActionCard(
              title: 'Vérifications AVS',
              subtitle: 'Approuver les nouvelles AVS',
              icon: Icons.verified_user,
              color: Colors.green.shade600,
              onTap: () => _tabController.animateTo(2),
            ),
            _buildQuickActionCard(
              title: 'Configuration système',
              subtitle: 'Paramètres et maintenance',
              icon: Icons.settings,
              color: Colors.orange.shade600,
              onTap: () => _tabController.animateTo(3),
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

  Widget _buildSystemAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertes système',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.orange.shade50,
          child: ListTile(
            leading: Icon(Icons.warning, color: Colors.orange.shade600),
            title: const Text('3 AVS en attente de vérification',
                style: TextStyle(color: Colors.black)),
            subtitle: const Text('Nécessitent une validation administrative',
                style: TextStyle(color: Colors.black)),
            trailing: TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('Voir'),
            ),
          ),
        ),
        Card(
          color: Colors.blue.shade50,
          child: ListTile(
            leading: Icon(Icons.info, color: Colors.blue.shade600),
            title: const Text('Système à jour',
                style: TextStyle(color: Colors.black)),
            subtitle: const Text('Dernière mise à jour: il y a 2 jours',
                style: TextStyle(color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé des utilisateurs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestion des utilisateurs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildUserTypeCount('AVS',
                            _systemStats['totalAvs'] ?? 0, Colors.orange),
                        _buildUserTypeCount('Familles',
                            _systemStats['totalFamilies'] ?? 0, Colors.purple),
                        _buildUserTypeCount(
                            'Coordinateurs',
                            _systemStats['totalCoordinators'] ?? 0,
                            Colors.indigo),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions de gestion
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Rechercher un utilisateur',
                    icon: Icons.search,
                    onPressed: _showUserSearchDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Créer un compte',
                    icon: Icons.person_add,
                    onPressed: _showCreateUserDialog,
                    backgroundColor: Colors.transparent,
                    textColor: Colors.red.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Liste des utilisateurs récents
            _buildRecentUsersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecentUsersList() {
    // Liste factice des utilisateurs récents
    final recentUsers = [
      {'name': 'Marie Dupont', 'role': 'AVS', 'status': 'active'},
      {'name': 'Famille Martin', 'role': 'Famille', 'status': 'active'},
      {'name': 'Jean Leclerc', 'role': 'AVS', 'status': 'pending'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Utilisateurs récents',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...recentUsers.map((user) => _buildUserCard(user)),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    Color statusColor =
        user['status'] == 'active' ? Colors.green : Colors.orange;
    String statusText = user['status'] == 'active' ? 'Actif' : 'En attente';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Text(
            user['name'][0],
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user['name']),
        subtitle: Text(user['role']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleUserAction(user, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('Voir')),
                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                const PopupMenuItem(
                    value: 'disable', child: Text('Désactiver')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête vérifications
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.verified_user,
                        color: Colors.green.shade600, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vérifications AVS',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Validation des pièces justificatives',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Liste des vérifications en attente
            _buildPendingVerificationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingVerificationsList() {
    // Liste factice des vérifications en attente
    final pendingVerifications = [
      {
        'name': 'Sophie Bernard',
        'documents': ['Diplôme AVS', 'Casier judiciaire', 'CV'],
        'submittedAt': '2025-01-15',
      },
      {
        'name': 'Thomas Moreau',
        'documents': ['Diplôme AVS', 'Certificat médical'],
        'submittedAt': '2025-01-14',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'En attente de vérification',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (pendingVerifications.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Toutes les vérifications sont à jour'),
                ],
              ),
            ),
          )
        else
          ...pendingVerifications
              .map((verification) => _buildVerificationCard(verification)),
      ],
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> verification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Text(
                    verification['name'][0],
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Soumis le ${verification['submittedAt']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Documents fournis:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: (verification['documents'] as List<String>)
                  .map(
                    (doc) => Chip(
                      label: Text(doc, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      _handleVerificationAction(verification, 'reject'),
                  child: const Text('Rejeter',
                      style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _handleVerificationAction(verification, 'approve'),
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

  Widget _buildSystemTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration système',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Paramètres généraux
            _buildSystemSettingsCard(),

            const SizedBox(height: 16),

            // Maintenance
            _buildMaintenanceCard(),

            const SizedBox(height: 16),

            // Sauvegardes
            _buildBackupCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres généraux',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              'Notifications push',
              'Activées',
              Icons.notifications,
              () {},
            ),
            _buildSettingTile(
              'Validation automatique',
              'Désactivée',
              Icons.auto_fix_high,
              () {},
            ),
            _buildSettingTile(
              'Mode maintenance',
              'Inactif',
              Icons.build,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
      String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildMaintenanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maintenance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Nettoyer le cache',
              icon: Icons.cleaning_services,
              onPressed: _cleanCache,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Optimiser la base de données',
              icon: Icons.tune,
              onPressed: _optimizeDatabase,
              backgroundColor: Colors.transparent,
              textColor: Colors.red.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sauvegardes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Dernière sauvegarde: Hier à 02:00',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Créer une sauvegarde',
              icon: Icons.backup,
              onPressed: _createBackup,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _nav.navigateTo(AppRoutes.profile);
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _handleUserAction(Map<String, dynamic> user, String action) {
    switch (action) {
      case 'view':
        // TODO: Voir les détails de l'utilisateur
        break;
      case 'edit':
        // TODO: Modifier l'utilisateur
        break;
      case 'disable':
        // TODO: Désactiver l'utilisateur
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action $action sur ${user['name']}')),
    );
  }

  void _handleVerificationAction(
      Map<String, dynamic> verification, String action) {
    String message = action == 'approve'
        ? 'Vérification approuvée pour ${verification['name']}'
        : 'Vérification rejetée pour ${verification['name']}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    // TODO: Implémenter la logique de vérification
  }

  void _showUserSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher un utilisateur'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Nom ou email',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un compte utilisateur'),
        content: const Text('Cette fonctionnalité sera bientôt disponible.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cleanCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache nettoyé avec succès')),
    );
  }

  void _optimizeDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Optimisation de la base de données en cours...')),
    );
  }

  void _createBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sauvegarde créée avec succès')),
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
