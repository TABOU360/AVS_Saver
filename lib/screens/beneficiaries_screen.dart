import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../models/beneficiary.dart';
import '../models/user.dart';
import '../core/app_routes.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  final DatabaseService _db = DatabaseService();
  final NavigationService _nav = NavigationService();

  List<Beneficiary> _beneficiaries = [];
  AppUser? _currentUser;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedConditionFilter = 'all';

  // Filtres par condition
  final List<String> _conditionFilters = [
    'all',
    'Autisme',
    'Troubles DYS',
    'Déficience motrice',
    'Déficience visuelle',
    'Déficience auditive',
    'Troubles comportementaux',
    'Déficience intellectuelle',
    'Troubles de l\'attention',
    'Épilepsie',
    'Diabète',
  ];

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser == null) {
        _nav.navigateToLogin();
        return;
      }

      final beneficiaries = await _db.getUserBeneficiaries(currentUser.id);

      if (mounted) {
        setState(() {
          _currentUser = currentUser;
          _beneficiaries = beneficiaries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement bénéficiaires: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  List<Beneficiary> get _filteredBeneficiaries {
    List<Beneficiary> filtered = _beneficiaries;

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((b) =>
              b.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.condition.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filtre par condition
    if (_selectedConditionFilter != 'all') {
      filtered = filtered
          .where((b) => b.condition.contains(_selectedConditionFilter))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes bénéficiaires'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBeneficiaries,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBeneficiaryDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Chargement des bénéficiaires...')
          : Column(
              children: [
                // Barre de recherche et filtres
                _buildSearchAndFilters(),

                // Liste des bénéficiaires
                Expanded(
                  child: _buildBeneficiariesList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBeneficiaryDialog,
        backgroundColor: Colors.purple.shade600,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un bénéficiaire...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: 12),

          // Filtre par condition
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _conditionFilters.map((condition) {
                final isSelected = _selectedConditionFilter == condition;
                final displayName = condition == 'all' ? 'Toutes' : condition;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedConditionFilter = selected ? condition : 'all';
                      });
                    },
                    selectedColor: Colors.purple.shade100,
                    checkmarkColor: Colors.purple.shade600,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiariesList() {
    final filteredBeneficiaries = _filteredBeneficiaries;

    if (filteredBeneficiaries.isEmpty) {
      if (_beneficiaries.isEmpty) {
        return EmptyStateWidget(
          icon: Icons.people_outline,
          title: 'Aucun bénéficiaire',
          message:
              'Vous n\'avez pas encore ajouté de bénéficiaire.\nCommencez par en ajouter un.',
          actionText: 'Ajouter un bénéficiaire',
          onAction: _showAddBeneficiaryDialog,
        );
      } else {
        return EmptyStateWidget(
          icon: Icons.search_off,
          title: 'Aucun résultat',
          message:
              'Aucun bénéficiaire ne correspond à vos critères de recherche.',
          actionText: 'Effacer les filtres',
          onAction: () => setState(() {
            _searchQuery = '';
            _selectedConditionFilter = 'all';
          }),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: _loadBeneficiaries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredBeneficiaries.length,
        itemBuilder: (context, index) {
          final beneficiary = filteredBeneficiaries[index];
          return _buildBeneficiaryCard(beneficiary);
        },
      ),
    );
  }

  Widget _buildBeneficiaryCard(Beneficiary beneficiary) {
    final ageGroup = _getAgeGroup(beneficiary.age);
    final conditionColor = _getConditionColor(beneficiary.condition);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _nav.navigateTo(
          AppRoutes.beneficiaryDetail,
          arguments: beneficiary,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et âge
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: conditionColor.withOpacity(0.1),
                    child: Text(
                      beneficiary.fullName.isNotEmpty
                          ? beneficiary.fullName[0].toUpperCase()
                          : 'B',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: conditionColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          beneficiary.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${beneficiary.age} ans',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ageGroup,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleBeneficiaryAction(beneficiary, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('Voir les détails'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Modifier'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'find_avs',
                        child: ListTile(
                          leading: Icon(Icons.search),
                          title: Text('Trouver une AVS'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Condition/Besoins
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: conditionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: conditionColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Besoins spécifiques:',
                      style: TextStyle(
                        fontSize: 12,
                        color: conditionColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      beneficiary.condition,
                      style: TextStyle(
                        fontSize: 14,
                        color: conditionColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Actions rapides
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _nav.navigateTo(
                        AppRoutes.beneficiaryDetail,
                        arguments: beneficiary,
                      ),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _nav.navigateTo(
                        AppRoutes.browseAvs,
                        arguments: beneficiary,
                      ),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Trouver AVS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    if (condition.contains('Autisme')) return Colors.blue;
    if (condition.contains('DYS')) return Colors.orange;
    if (condition.contains('motrice')) return Colors.green;
    if (condition.contains('visuelle')) return Colors.purple;
    if (condition.contains('auditive')) return Colors.red;
    if (condition.contains('comportement')) return Colors.teal;
    if (condition.contains('intellectuelle')) return Colors.indigo;
    if (condition.contains('attention')) return Colors.amber;
    return Colors.grey;
  }

  String _getAgeGroup(int age) {
    if (age < 3) return 'Petite enfance';
    if (age < 6) return 'Préscolaire';
    if (age < 12) return 'Enfance';
    if (age < 18) return 'Adolescence';
    if (age < 25) return 'Jeune adulte';
    return 'Adulte';
  }

  void _handleBeneficiaryAction(Beneficiary beneficiary, String action) {
    switch (action) {
      case 'view':
        _nav.navigateTo(AppRoutes.beneficiaryDetail, arguments: beneficiary);
        break;
      case 'edit':
        _showEditBeneficiaryDialog(beneficiary);
        break;
      case 'find_avs':
        _nav.navigateTo(AppRoutes.browseAvs, arguments: beneficiary);
        break;
      case 'delete':
        _showDeleteConfirmDialog(beneficiary);
        break;
    }
  }

  void _showAddBeneficiaryDialog() {
    _showBeneficiaryDialog();
  }

  void _showEditBeneficiaryDialog(Beneficiary beneficiary) {
    _showBeneficiaryDialog(beneficiary: beneficiary);
  }

  void _showBeneficiaryDialog({Beneficiary? beneficiary}) {
    final isEditing = beneficiary != null;
    final nameController =
        TextEditingController(text: beneficiary?.fullName ?? '');
    final ageController =
        TextEditingController(text: beneficiary?.age.toString() ?? '');
    final conditionController =
        TextEditingController(text: beneficiary?.condition ?? '');
    final formKey = GlobalKey<FormState>();

    String selectedCondition =
        beneficiary?.condition ?? AppConstants.medicalConditions.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            isEditing ? 'Modifier le bénéficiaire' : 'Ajouter un bénéficiaire'),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir le nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(
                      labelText: 'Âge',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                      suffixText: 'ans',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir l\'âge';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 0 || age > 120) {
                        return 'Âge invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCondition,
                    decoration: const InputDecoration(
                      labelText: 'Condition/Besoins',
                      prefixIcon: Icon(Icons.medical_services),
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.medicalConditions
                        .map(
                          (condition) => DropdownMenuItem(
                            value: condition,
                            child: Text(condition),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedCondition = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: conditionController,
                    decoration: const InputDecoration(
                      labelText: 'Informations additionnelles',
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder(),
                      helperText: 'Précisions sur les besoins spécifiques',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && _currentUser != null) {
                try {
                  final finalCondition = conditionController.text
                          .trim()
                          .isNotEmpty
                      ? '$selectedCondition - ${conditionController.text.trim()}'
                      : selectedCondition;

                  if (isEditing) {
                    // TODO: Implémenter la modification
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Modification non encore implémentée')),
                    );
                  } else {
                    await _db.addBeneficiary(
                      familyId: _currentUser!.id,
                      fullName: nameController.text.trim(),
                      age: int.parse(ageController.text),
                      condition: finalCondition,
                      additionalInfo: conditionController.text.trim(),
                    );
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Bénéficiaire modifié avec succès'
                              : 'Bénéficiaire ajouté avec succès',
                        ),
                      ),
                    );
                    _loadBeneficiaries();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Beneficiary beneficiary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le bénéficiaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Êtes-vous sûr(e) de vouloir supprimer ${beneficiary.fullName} ?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cette action est irréversible.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter la suppression
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Suppression non encore implémentée')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
