import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _login() async {
    try {
      // 1️⃣ Authentification avec FirebaseAuth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2️⃣ Récupération du profil Firestore
        DocumentSnapshot userDoc =
        await _firestore.collection("users").doc(user.uid).get();

        if (userDoc.exists) {
          var profileData = userDoc.data() as Map<String, dynamic>;

          // Exemple : afficher le nom récupéré
          print("Bienvenue ${profileData["nom"]}");

          // Ici tu peux naviguer vers la page d’accueil avec les infos du profil
          Navigator.pushReplacementNamed(context, "/home",
              arguments: profileData);
        } else {
          print("⚠️ Aucun profil trouvé pour cet utilisateur !");
        }
      }
    } catch (e) {
      print("Erreur de connexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de la connexion : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connexion")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text("Se connecter"),
            ),
          ],
        ),
      ),
    );
  }
}
