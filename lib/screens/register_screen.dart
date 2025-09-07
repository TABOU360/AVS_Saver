import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
import '../core/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  // Controllers étape 1 (Info personnelles)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controllers étape 2 (Info rôle)
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // État
  int _currentStep = 0;
  String _selectedRole = AppConstants.roleFamille;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Spécifique AVS
  final List<String> _selectedSkills = [];
  final _hourlyRateController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _authService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user!.uid;
      final fullName = '${_firstNameController.text} ${_lastNameController.text}';

      final userProfile = {
        'uid': uid,
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'name': fullName,
        'role': _selectedRole,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'createdAt': DateTime.now(),
      };

      // ⚡ Conversion Object? -> String
      await _databaseService.createUserProfile(
        uid: uid,
        email: (userProfile["email"] ?? '') as String,
        name: fullName,
        role: _selectedRole,
        additionalData: userProfile,
      );

      if (_selectedRole == AppConstants.roleAvs) {
        await _databaseService.createAvsProfile(
          uid: uid,
          name: fullName,
          skills: _selectedSkills,
          hourlyRate: double.tryParse(_hourlyRateController.text) ?? 15.0,
          bio: _bioController.text,
        );
      }

      await _authService.updateUsername(username: fullName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successAccountCreated),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _validateStep1()) {
      setState(() => _currentStep = 1);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentStep == 1 && _validateStep2()) {
      setState(() => _currentStep = 2);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _validateStep1() {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        RegExp(RegexConstants.email).hasMatch(_emailController.text) &&
        _passwordController.text.length >= AppConstants.minPasswordLength &&
        _passwordController.text == _confirmPasswordController.text;
  }

  bool _validateStep2() {
    if (_selectedRole == AppConstants.roleAvs) {
      return _selectedSkills.isNotEmpty &&
          _hourlyRateController.text.isNotEmpty &&
          _bioController.text.isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: _previousStep)
            : null,
        title: Text('Inscription ${_currentStep + 1}/3', style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Précédent'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: _currentStep == 2 ? 'S\'inscrire' : 'Suivant',
                      isLoading: _isLoading,
                      onPressed: _currentStep == 2 ? _handleRegistration : _nextStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations personnelles', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Commençons par vos informations de base', style: TextStyle(fontSize: 16, color: Colors.black)),
          const SizedBox(height: 32),

          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
            validator: (value) => value?.isEmpty == true ? 'Prénom requis' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
            validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
            validator: (value) {
              if (value?.isEmpty == true) return 'Email requis';
              if (!RegExp(RegexConstants.email).hasMatch(value!)) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty == true) return 'Mot de passe requis';
              if (value!.length < AppConstants.minPasswordLength) return 'Minimum ${AppConstants.minPasswordLength} caractères';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),

          const SizedBox(height: 30),

          // 🔹 S'inscrire avec Google / Facebook
          const Center(child: Text("S'inscrire avec :", style: TextStyle(fontSize: 16))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: () {
                  // TODO: Implémenter Google
                },
                icon: Image.asset("assets/images/google.png", height: 24),
                label: const Text("Google"),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // TODO: Implémenter Facebook
                },
                icon: Image.asset("assets/images/facebook.png", height: 24),
                label: const Text("Facebook"),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Vous avez déjà un compte ?"),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                child: const Text(
                  "Se connecter",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    // Même code que précédemment pour les rôles et infos complémentaires
    // ...
    return const SizedBox();
  }

  Widget _buildStep3() {
    // Même code que précédemment pour profil AVS ou résumé
    // ...
    return const SizedBox();
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.roleFamille:
        return 'Famille';
      case AppConstants.roleAvs:
        return 'AVS (Auxiliaire de Vie Scolaire)';
      case AppConstants.roleCoordinateur:
        return 'Coordinateur';
      default:
        return role;
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case AppConstants.roleFamille:
        return 'Rechercher et réserver des services AVS';
      case AppConstants.roleAvs:
        return 'Proposer vos services d\'accompagnement';
      case AppConstants.roleCoordinateur:
        return 'Gérer et coordonner les interventions';
      default:
        return '';
    }
  }
}
