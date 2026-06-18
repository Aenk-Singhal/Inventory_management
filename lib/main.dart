import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management_system/screens/Startup.dart';
import 'package:inventory_management_system/services/registration_service.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp();

await SystemChrome.setPreferredOrientations([
DeviceOrientation.portraitUp,
]);

runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        primaryColor: Colors.white,
        cardColor: const Color(0xFF2E2E2E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Colors.white24,
          selectionHandleColor: Colors.white70,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2E2E2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white70,
          backgroundColor: Color(0xFF2E2E2E),
        ),
      ),
      home: RegistrationGuard(
        navigatorKey: navigatorKey,
        child: const StartUp(),
      ),
    );
  }
}
