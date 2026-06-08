import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
/* import 'package:firebase_core/firebase_core.dart'; */
import 'core/constants.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await initializeDateFormatting('bn', null);

  // await Firebase.initializeApp();

  runApp(const ProviderScope(child: KrishokApp()));
}

class KrishokApp extends ConsumerWidget {
  const KrishokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Krishok',
      debugShowCheckedModeBanner: false,
      routes: AppRouter.routes,
      home: const _AuthGate(),
    );
  }
}

/// Watches [authProvider] and routes to the correct screen on cold start.
/// Shows a branded splash while the session check is in flight.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return authAsync.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => const _SplashScreen(), // treat errors as logged-out
      data: (authState) {
        if (authState.isAuthenticated) {
          // Already has a valid session — go straight to home.
          return AppRouter.routes[AppRouter.home]!(context);
        }
        // No session — show login.
        return AppRouter.routes[AppRouter.login]!(context);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grass_rounded, color: Color(0xFF2E7D32), size: 56),
            SizedBox(height: 16),
            Text(
              'কৃষক',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Color(0xFF2E7D32),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
