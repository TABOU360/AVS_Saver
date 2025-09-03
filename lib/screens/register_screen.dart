import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'package:avs_saver/models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userCredential = await authService.value.createAccount(
          email: _emailController.text,
          password: _passwordController.text,
        );

        await authService.value.updateUsername(
          username: "${_firstNameController.text} ${_lastNameController.text}",
        );
        // Dans _register() après updateUsername
        final appUser = AppUser(
          id: userCredential.user!.uid,
          role: 'famille',  // Rôle par défaut ; ajustez basé sur un champ de formulaire si besoin
          name: "${_firstNameController.text} ${_lastNameController.text}",
          email: _emailController.text,
        );
        await FirebaseFirestore.instance.collection('users').doc(appUser.id).set(appUser.toMap());

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Erreur inconnue')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    "assets/images/logo.jpg",
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Créez votre compte",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    hintText: "Entrez votre nom",
                    labelText: "Nom",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: "Entrez votre prénom",
                    labelText: "Prénom",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.mail),
                    hintText: "Entrez votre mail",
                    labelText: "E-mail",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) return 'Champ requis';
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'E-mail invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    hintText: "Entrez votre mot de passe",
                    labelText: "Mot de passe",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  obscureText: true,
                  validator: (value) => value!.length < 6 ? 'Mot de passe trop court' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: "Confirmez votre mot de passe",
                    labelText: "Confirmation mot de passe",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  obscureText: true,
                  validator: (value) => value != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: "S'inscrire",
                  isLoading: _isLoading,
                  onPressed: _register,
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider(thickness: 0.5)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("Ou continuez avec"),
                    ),
                    Expanded(child: Divider(thickness: 0.5)),
                  ],
                ),
                // Ajoute des boutons sociaux si besoin
              ],
            ),
          ),
        ],
      ),
    );
  }
}