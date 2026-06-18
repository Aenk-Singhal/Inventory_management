import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory_management_system/widgets/Auth.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';
import 'package:inventory_management_system/services/registration_service.dart';

class StartUp extends StatefulWidget {
  const StartUp({super.key});

  @override
  State<StartUp> createState() => _StartUpState();
}

class _StartUpState extends State<StartUp> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email;

    if (email == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Auth()),
      );
      return;
    }

    final isRegistered = await RegistrationService.checkRegistration(email);

    if (!mounted) return;

    if (isRegistered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else {
      // Keep the Google session so invite registration can continue on Auth.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Auth()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenSize.width * 0.6),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: screenSize.width * 0.6,
                height: screenSize.height * 0.3,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: screenSize.height * 0.05),
            Center(
               child: Text(
                 "Developed With ❤️",
                 style: TextStyle(
                   fontFamily: 'Inter',
                   fontSize: screenSize.height * 0.03,
                   color: Colors.white
                 ),
               ),
            ),
            Center(
              child: Text(
                "Backstage 25'-26'",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: screenSize.height * 0.03,
                  color: Colors.white
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
