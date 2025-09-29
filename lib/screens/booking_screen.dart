import 'package:avs_saver/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/avs.dart';
import '../models/beneficiary.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';
import '../utils/date_helper.dart';
import '../widgets/custom_button.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  final NavigationService _nav = NavigationService();

  Avs? _selectedAvs;
  Beneficiary? _selectedBeneficiary;
  List<Beneficiary> _beneficiaries = [];
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedSessionType = 'domicile';
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Types de sessions disponibles
  final Map<String, Map<String, dynamic>> _sessionTypes = {
    'domicile': {
      'title': 'À domicile',
      'icon': Icons.home,
      'description': 'Intervention au domicile du bénéficiaire',
      'color': Colors.blue,
    },
    'centre': {
      'title': 'En centre',
      'icon': Icons.business,
      'description': 'Session dans un centre spécialisé',
      'color': Colors.green,
    },
    'ecole': {
      'title': 'À l\'école',
      'icon': Icons.school,
      'description': 'Accompagnement scolaire',
      'color': Colors.orange,
    },
    'exterieur': {
      'title': 'Activité extérieure',
      'icon': Icons.nature_people,
      'description': 'Sortie ou activité en extérieur',
      'color': Colors.purple,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer l'AVS depuis les arguments
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Avs) {
        _selectedAvs = args;
      }

      // Charger les bénéficiaires de l'utilisateur actuel
      final currentUser = await _db.getCurrentUser();
      if (currentUser != null) {
        final beneficiaries = await _db.getUserBeneficiaries(currentUser.id);
        setState(() {
          _beneficiaries = beneficiaries;
          if (_beneficiaries.isNotEmpty) {
            _selectedBeneficiary = _beneficiaries.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue.shade600,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 10, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue.shade600,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Ajuster automatiquement l'heure de fin si nécessaire
          if (_endTime == null || _endTime!.hour <= picked.hour) {
            _endTime = TimeOfDay(
              hour: (picked.hour + 1) % 24,
              minute: picked.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  bool _validateTimes() {
    if (_startTime == null || _endTime == null) return false;

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    return endMinutes > startMinutes;
  }

  Future<void> _submitBookingRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showErrorSnackBar('Veuillez sélectionner une date');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showErrorSnackBar('Veuillez sélectionner les heures');
      return;
    }
    if (!_validateTimes()) {
      _showErrorSnackBar('L\'heure de fin doit être après l\'heure de début');
      return;
    }
    if (_selectedBeneficiary == null) {
      _showErrorSnackBar('Veuillez sélectionner un bénéficiaire');
      return;
    }
    if (_selectedAvs == null) {
      _showErrorSnackBar('AVS non sélectionnée');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer les DateTime pour début et fin
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // Créer la demande de réservation
      await _db.createBookingRequest(
        familyId: currentUser.id,
        avsId: _selectedAvs!.id,
        beneficiaryId: _selectedBeneficiary!.id,
        startTime: startDateTime,
        endTime: endDateTime,
        address: _addressController.text.trim(),
        notes: _buildSessionNotes(),
      );

      // Succès
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Erreur création réservation: $e');
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la création: $e');
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _buildSessionNotes() {
    final sessionType = _sessionTypes[_selectedSessionType];
    String notes = 'Type de session: ${sessionType?['title']}\n';

    if (_notesController.text.trim().isNotEmpty) {
      notes += '\nNotes additionnelles:\n${_notesController.text.trim()}';
    }

    return notes;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green.shade600, size: 64),
        title: const Text('Demande envoyée !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Votre demande de réservation a été transmise à ${_selectedAvs?.name}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Récapitulatif:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Date: ${DateHelpers.formatDate(_selectedDate!)}'),
                  Text(
                      'Heure: ${_startTime!.format(context)} - ${_endTime!.format(context)}'),
                  Text('Bénéficiaire: ${_selectedBeneficiary?.fullName}'),
                  Text(
                      'Type: ${_sessionTypes[_selectedSessionType]?['title']}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialogue
              _nav.goBack(); // Retourner à l'écran précédent
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Parfait !'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle réservation'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations AVS
                    _buildAvsInfoCard(),
                    const SizedBox(height: 16),

                    // Sélection du bénéficiaire
                    _buildBeneficiarySelection(),
                    const SizedBox(height: 16),

                    // Sélection de la date et heure
                    _buildDateTimeSelection(),
                    const SizedBox(height: 16),

                    // Type de session
                    _buildSessionTypeSelection(),
                    const SizedBox(height: 16),

                    // Adresse
                    _buildAddressField(),
                    const SizedBox(height: 16),

                    // Notes additionnelles
                    _buildNotesField(),
                    const SizedBox(height: 24),

                    // Récapitulatif
                    if (_isFormValid()) _buildSummaryCard(),
                    const SizedBox(height: 24),

                    // Bouton de soumission
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvsInfoCard() {
    if (_selectedAvs == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                _selectedAvs!.name.isNotEmpty
                    ? _selectedAvs!.name[0].toUpperCase()
                    : 'A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedAvs!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedAvs!.verified) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified,
                            color: Colors.green.shade600, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text('${_selectedAvs!.rating.toStringAsFixed(1)}'),
                      const SizedBox(width: 16),
                      Text(
                        '${_selectedAvs!.hourlyRate.toStringAsFixed(0)}€/h',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedAvs!.skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: _selectedAvs!.skills
                          .take(3)
                          .map(
                            (skill) => Chip(
                              label: Text(skill,
                                  style: const TextStyle(fontSize: 10)),
                              backgroundColor: Colors.blue.shade50,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiarySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bénéficiaire',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_beneficiaries.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                          'Aucun bénéficiaire trouvé. Ajoutez-en un dans votre profil.',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<Beneficiary>(
                value: _selectedBeneficiary,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _beneficiaries
                    .map((beneficiary) => DropdownMenuItem(
                          value: beneficiary,
                          child: Text(
                              '${beneficiary.fullName} (${beneficiary.age} ans)'),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedBeneficiary = value),
                validator: (value) =>
                    value == null ? 'Sélectionnez un bénéficiaire' : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date et horaires',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Sélection de date
            InkWell(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? DateHelpers.formatDate(_selectedDate!)
                          : 'Sélectionner une date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? Colors.black
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Sélection des heures
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 8),
                          Text(
                            _startTime?.format(context) ?? 'Début',
                            style: TextStyle(
                              color: _startTime != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled),
                          const SizedBox(width: 8),
                          Text(
                            _endTime?.format(context) ?? 'Fin',
                            style: TextStyle(
                              color: _endTime != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_startTime != null && _endTime != null && !_validateTimes())
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'L\'heure de fin doit être après l\'heure de début',
                  style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type d\'intervention',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: _sessionTypes.entries.map((entry) {
                final isSelected = _selectedSessionType == entry.key;
                final sessionData = entry.value;

                return InkWell(
                  onTap: () => setState(() => _selectedSessionType = entry.key),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? sessionData['color'].withOpacity(0.1)
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: isSelected
                            ? sessionData['color']
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sessionData['icon'],
                          color: isSelected
                              ? sessionData['color']
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sessionData['title'],
                            style: TextStyle(
                              color: isSelected
                                  ? sessionData['color']
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lieu d\'intervention',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse complète',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
                helperText: 'Saisissez l\'adresse où aura lieu l\'intervention',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir une adresse';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes additionnelles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Instructions spéciales, besoins particuliers...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final sessionType = _sessionTypes[_selectedSessionType];
    final duration = _calculateDuration();
    final estimatedCost = _calculateEstimatedCost();

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Récapitulatif',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('AVS', _selectedAvs?.name ?? ''),
            _buildSummaryRow(
                'Bénéficiaire', _selectedBeneficiary?.fullName ?? ''),
            _buildSummaryRow(
                'Date',
                _selectedDate != null
                    ? DateHelpers.formatDate(_selectedDate!)
                    : ''),
            _buildSummaryRow('Horaires',
                '${_startTime?.format(context)} - ${_endTime?.format(context)}'),
            _buildSummaryRow('Durée', duration),
            _buildSummaryRow('Type', sessionType?['title'] ?? ''),
            _buildSummaryRow('Coût estimé', estimatedCost),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: 'Envoyer la demande',
      icon: Icons.send,
      onPressed:
          _isFormValid() && !_isSubmitting ? _submitBookingRequest : null,
      isLoading: _isSubmitting,
      backgroundColor: Colors.blue.shade600,
    );
  }

  bool _isFormValid() {
    return _selectedAvs != null &&
        _selectedBeneficiary != null &&
        _selectedDate != null &&
        _startTime != null &&
        _endTime != null &&
        _validateTimes() &&
        _addressController.text.trim().isNotEmpty;
  }

  String _calculateDuration() {
    if (_startTime == null || _endTime == null) return '';

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final durationMinutes = endMinutes - startMinutes;

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  String _calculateEstimatedCost() {
    if (_selectedAvs == null || _startTime == null || _endTime == null)
      return '';

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final durationHours = (endMinutes - startMinutes) / 60;

    final cost = durationHours * _selectedAvs!.hourlyRate;
    return '${cost.toStringAsFixed(0)}€';
  }
}
