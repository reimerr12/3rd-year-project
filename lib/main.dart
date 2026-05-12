import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
/* import 'package:firebase_core/firebase_core.dart'; */
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/router.dart';
/* import 'screens/auth/login_screen.dart'; */
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // await Firebase.initializeApp();

  runApp(const ProviderScope(child: KrishokApp()));
}

class KrishokApp extends StatelessWidget {
  const KrishokApp({super.key});

  @override
  Widget build(BuildContext context) {
    /* final session = Supabase.instance.client.auth.currentSession; */

    return MaterialApp(
      title: 'Krishok',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: AppRouter.routes,
      initialRoute: AppRouter.home,
    );
  }
}
