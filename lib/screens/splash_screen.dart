import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await authProvider.loadToken();
      
      if (authProvider.isAuthenticated && !authProvider.isGuestMode) {
        print('Validando token existente...');
        final isValid = await authProvider.validateToken();
        
        if (!isValid) {
          print('Token expirado - redirigiendo al login');
          _navigateToLogin();
          return;
        }
        
        if (authProvider.user == null) {
          await authProvider.fetchUser();
        }
      }
      
      _navigateToCorrectScreen(authProvider);
      
    } catch (e) {
      print('Error en _checkAuth: $e');
      _navigateToLogin();
    }
  }

  void _navigateToCorrectScreen(AuthProvider authProvider) {
    if (!mounted) return;
    
    if (authProvider.isAuthenticated) {
      print('Usuario autenticado - navegando al dashboard');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      print('Usuario no autenticado - navegando al login');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Cargando UnisonMap...')
          ],
        ),
      ),
    );
  }
}