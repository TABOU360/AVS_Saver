import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';
import '../core/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _role = "AVS";
  bool _isLoading = false;

  /// Aller à l’étape suivante
  void _nextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _registerUser();
      }
    }
  }

  /// Retour à l’étape précédente
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  /// Enregistrement Firebase
  Future<void> _registerUser() async {
    setState(() => _isLoading = true);
    try {
      // 1️⃣ Création de l’utilisateur Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2️⃣ Enregistrement des infos dans Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "role": _role,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 3️⃣ Redirection vers Home (ou autre page)
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inscription réussie ✅")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Erreur inconnue";
      if (e.code == "email-already-in-use") {
        message = "Cet email est déjà utilisé.";
      } else if (e.code == "weak-password") {
        message = "Mot de passe trop faible.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          color: AppColors.secondaryText, fontWeight: FontWeight.w600),
      prefixIcon:
          icon != null ? Icon(icon, color: AppColors.medicalBlue) : null,
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  // === Étape 1 : Infos personnelles ===
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Informations personnelles",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _firstNameController,
            style: const TextStyle(color: AppColors.darkText),
            cursorColor: AppColors.medicalBlue,
            decoration:
                _inputDecoration(label: "Prénom", icon: Icons.person_outline),
            validator: (v) =>
                v!.isEmpty ? "Veuillez entrer votre prénom" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            style: const TextStyle(color: AppColors.darkText),
            cursorColor: AppColors.medicalBlue,
            decoration: _inputDecoration(label: "Nom", icon: Icons.person),
            validator: (v) => v!.isEmpty ? "Veuillez entrer votre nom" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: AppColors.darkText),
            cursorColor: AppColors.medicalBlue,
            decoration:
                _inputDecoration(label: "Email", icon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v!.isEmpty) return "Veuillez entrer un email";
              if (!RegExp(RegexConstants.email).hasMatch(v)) {
                return "Email invalide";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            style: const TextStyle(color: AppColors.darkText),
            cursorColor: AppColors.medicalBlue,
            obscureText: _obscurePassword,
            decoration: _inputDecoration(
                    label: "Mot de passe", icon: Icons.lock_outline)
                .copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.secondaryText),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v!.isEmpty) return "Veuillez entrer un mot de passe";
              if (v.length < AppConstants.minPasswordLength) {
                return "Minimum ${AppConstants.minPasswordLength} caractères";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            style: const TextStyle(color: AppColors.darkText),
            cursorColor: AppColors.medicalBlue,
            obscureText: _obscureConfirmPassword,
            decoration: _inputDecoration(
                    label: "Confirmer le mot de passe", icon: Icons.lock)
                .copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.secondaryText),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (v) {
              if (v != _passwordController.text) {
                return "Les mots de passe ne correspondent pas";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // === Étape 2 : Infos supplémentaires ===
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Informations supplémentaires",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: AppColors.darkText),
            cursorColor: AppColors.medicalBlue,
            decoration: _inputDecoration(label: "Téléphone", icon: Icons.phone),
            keyboardType: TextInputType.phone,
            validator: (v) => v!.isEmpty ? "Veuillez entrer un numéro" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            style: const TextStyle(color: AppColors.darkText),
            cursorColor: AppColors.medicalBlue,
            decoration: _inputDecoration(label: "Adresse", icon: Icons.home),
            validator: (v) => v!.isEmpty ? "Veuillez entrer une adresse" : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _role,
            style: const TextStyle(color: AppColors.darkText),
            decoration: _inputDecoration(label: "Rôle", icon: Icons.group),
            items: const [
              DropdownMenuItem(value: "AVS", child: Text("AVS")),
              DropdownMenuItem(value: "Famille", child: Text("Famille")),
              DropdownMenuItem(value: "Tuteur", child: Text("Tuteur")),
              DropdownMenuItem(value: "Autre", child: Text("Autre")),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
        ],
      ),
    );
  }

  // === Étape 3 : Récapitulatif ===
  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Récapitulatif",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText)),
          const SizedBox(height: 20),
          Text(
              "👤 Nom : ${_firstNameController.text} ${_lastNameController.text}",
              style: const TextStyle(color: AppColors.darkText)),
          Text("📧 Email : ${_emailController.text}",
              style: const TextStyle(color: AppColors.darkText)),
          Text("📱 Téléphone : ${_phoneController.text}",
              style: const TextStyle(color: AppColors.darkText)),
          Text("🏠 Adresse : ${_addressController.text}",
              style: const TextStyle(color: AppColors.darkText)),
          Text("👥 Rôle : $_role",
              style: const TextStyle(color: AppColors.darkText)),
          const SizedBox(height: 30),
          const Text(
            "Vérifiez vos informations avant de confirmer.",
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [_buildStep1(), _buildStep2(), _buildStep3()];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Inscription"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 18, offset: Offset(0, 8))
              ],
            ),
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: steps[_currentStep],
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.darkText,
                  ),
                  child: const Text("Précédent"),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.medicalBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_currentStep == 2 ? "Confirmer" : "Suivant"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
