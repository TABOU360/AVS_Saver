import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Récupération infos utilisateur dans Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Stocker les infos utilisateur (à adapter selon votre state management)
          // Ex: Provider.of<UserProvider>(context, listen: false).setUser(userDoc.data());
          debugPrint("Utilisateur connecté: ${user.email}");
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_getErrorMessage(e.code)),
              backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Une erreur inattendue s'est produite"),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      default:
        return 'Erreur de connexion';
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Implémentez la connexion Google
    debugPrint("Google Sign-In clicked");
    // await _authService.signInWithGoogle();
  }

  Future<void> _handleFacebookSignIn() async {
    // Implémentez la connexion Facebook
    debugPrint("Facebook Sign-In clicked");
    // await _authService.signInWithFacebook();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo area
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.medicalBlue, AppColors.aqua]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: Offset(0, 6))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/images/logo.jpg",
                          height: 88,
                          width: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.medical_services,
                                  size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'AVS Saver',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.darkText,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous à votre compte',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 22),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: AppColors.darkText),
                            cursorColor: AppColors.medicalBlue,
                            decoration: _fieldDecoration(
                                label: 'Email', prefix: Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email requis';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: AppColors.darkText),
                            cursorColor: AppColors.medicalBlue,
                            obscureText: _obscurePassword,
                            decoration: _fieldDecoration(
                                    label: 'Mot de passe',
                                    prefix: Icons.lock_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.secondaryText),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Mot de passe requis'
                                : value.length < 6
                                    ? 'Le mot de passe doit contenir au moins 6 caractères'
                                    : null,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: const Text('Mot de passe oublié ?',
                                  style: TextStyle(
                                      color: AppColors.medicalBlue,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Connexion button
                          CustomButton(
                            text: "Se connecter",
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Separator
                    const Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: Color(0xFF1E4955), thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text("ou",
                              style: TextStyle(
                                  color: Color(0xFF1E4955),
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                            child: Divider(
                                color: Color(0xFF1E4955), thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Social login buttons - maintenant cliquables
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _handleGoogleSignIn,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Image.asset(
                              "assets/images/google.png",
                              height: 32,
                              width: 32,
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 18), // Correction: spécifier width
                        GestureDetector(
                          onTap: _handleFacebookSignIn,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Image.asset(
                              "assets/images/facebook.png",
                              height: 32,
                              width: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas encore de compte ? ",
                            style: TextStyle(color: AppColors.secondaryText)),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                          child: const Text(
                            "S'inscrire",
                            style: TextStyle(
                                color: AppColors.medicalBlue,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.home),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side:
                              const BorderSide(color: AppColors.surfaceBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Text('Continuer en mode démo',
                            style: TextStyle(color: AppColors.darkText)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
      {required String label, required IconData prefix}) {
    return InputDecoration(
      prefixIcon: Icon(prefix, color: AppColors.medicalBlue),
      hintText: 'Entrez votre $label'.toLowerCase(),
      labelText: label,
      labelStyle: const TextStyle(
          color: AppColors.secondaryText, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }
}
