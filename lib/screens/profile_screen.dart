import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  final bool isFirstSetup;
  final User? user; // User Firebase (optionnel pour premier setup)

  const ProfileScreen({
    super.key,
    this.isFirstSetup = false,
    this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final NavigationService _navigationService = NavigationService();

  AppUser? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final firebaseUser = _authService.currentUser ?? widget.user;
      if (firebaseUser == null) {
        if (mounted) {
          _navigationService.navigateToLogin();
        }
        return;
      }

      final userProfile =
          await _databaseService.getUserProfile(firebaseUser.uid);
      if (mounted) {
        setState(() {
          _user = userProfile;
          _isLoading = false;

          if (userProfile != null) {
            _nameController.text = userProfile.name;
            _selectedRole = userProfile.role;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Erreur lors du chargement du profil');
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackbar('Le nom est requis');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) return;

      await _databaseService.updateUserProfile(firebaseUser.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'role': _selectedRole,
        'updatedAt': DateTime.now(),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        _showSuccessSnackbar('Profil mis à jour avec succès');

        // Si c'est le premier setup, rediriger vers l'accueil
        if (widget.isFirstSetup) {
          _navigationService.navigateToHome();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Erreur lors de la mise à jour: $e');
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      // Conserver les valeurs actuelles pour l'édition
      if (_user != null) {
        _nameController.text = _user!.name;
        _selectedRole = _user!.role;
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // Revenir aux valeurs originales
      if (_user != null) {
        _nameController.text = _user!.name;
        _selectedRole = _user!.role;
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                _navigationService.navigateToLogin();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstSetup ? 'Compléter le profil' : 'Mon profil'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: _isLoading ? null : _cancelEditing,
                  tooltip: 'Annuler',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _isLoading ? null : _startEditing,
                  tooltip: 'Modifier le profil',
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Profil non trouvé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Impossible de charger votre profil',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Réessayer',
            onPressed: _loadUserData,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Se déconnecter',
            onPressed: _handleLogout,
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar/Photo de profil
        _buildProfileHeader(),

        const SizedBox(height: 24),

        // Informations du profil
        if (_isEditing) _buildEditForm() else _buildProfileInfo(),

        const SizedBox(height: 32),

        // Boutons d'action
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: _authService.currentUser?.photoURL != null
                ? NetworkImage(_authService.currentUser!.photoURL!)
                    as ImageProvider
                : const AssetImage(AppConstants.placeholderAvatar),
            child: _isEditing
                ? Stack(
                    children: [
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(Icons.camera_alt,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                // TODO: Implémenter le changement de photo
                _showErrorSnackbar('Changement de photo non implémenté');
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Changer la photo'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Nom complet', _user!.name, Icons.person),
            const Divider(),
            _buildInfoRow('Email', _user!.email, Icons.email),
            const Divider(),
            _buildInfoRow('Rôle', _getRoleDisplayName(_user!.role), Icons.work),
            if (_user!.phone?.isNotEmpty ?? false) ...[
              const Divider(),
              _buildInfoRow('Téléphone', _user!.phone!, Icons.phone),
            ],
            if (_user!.address?.isNotEmpty ?? false) ...[
              const Divider(),
              _buildInfoRow('Adresse', _user!.address!, Icons.home),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole.isNotEmpty ? _selectedRole : null,
              decoration: const InputDecoration(
                labelText: 'Rôle',
                prefixIcon: Icon(Icons.work),
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: AppConstants.roleFamille,
                  child: Text(_getRoleDisplayName(AppConstants.roleFamille)),
                ),
                DropdownMenuItem(
                  value: AppConstants.roleAvs,
                  child: Text(_getRoleDisplayName(AppConstants.roleAvs)),
                ),
                DropdownMenuItem(
                  value: AppConstants.roleCoordinateur,
                  child:
                      Text(_getRoleDisplayName(AppConstants.roleCoordinateur)),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone (optionnel)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse (optionnel)',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isEditing) ...[
          CustomButton(
            text: 'Enregistrer les modifications',
            onPressed: _isLoading ? null : _updateProfile,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isLoading ? null : _cancelEditing,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Annuler'),
          ),
        ] else ...[
          CustomButton(
            text: 'Modifier le profil',
            onPressed: _startEditing,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Se déconnecter',
            onPressed: _handleLogout,
            backgroundColor: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.roleFamille:
        return "Famille";
      case AppConstants.roleAvs:
        return "AVS";
      case AppConstants.roleCoordinateur:
        return "Coordinateur";
      case AppConstants.roleAdmin:
        return "Administrateur";
      default:
        return role;
    }
  }
}
