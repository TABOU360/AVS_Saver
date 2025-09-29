import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/auth_wrapper.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  final bool _showButton = true;

  @override
  void initState() {
    super.initState();
    // Petite animation pulsée et infinie
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _scale = Tween<double>(begin: 0.95, end: 1.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed)
        _ctrl.reverse();
      else if (status == AnimationStatus.dismissed) _ctrl.forward();
    });
    _ctrl.forward();

    // Forcer status bar en foncé pour look médical propre
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _proceed() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Dégradé léger en fond
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.background, AppColors.inputFill],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _scale,
                    builder: (_, child) =>
                        Transform.scale(scale: _scale.value, child: child),
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.medicalBlue, AppColors.aqua]),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, 8))
                        ],
                      ),
                      child: const Center(
                          child: Icon(Icons.health_and_safety_rounded,
                              size: 78, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('AVS Saver',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText)),
                  const SizedBox(height: 8),
                  Text(
                      'Choisissez la personne idéale pour ceux que vous aimez ',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.secondaryText)),
                ],
              ),
            ),
            // Bouton "Suivant" pour que l'utilisateur ferme le splash quand il veut
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _showButton ? 1 : 0,
                child: ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: AppColors.medicalBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Suivant',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
