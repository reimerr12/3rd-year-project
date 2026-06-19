import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  runApp(const ProviderScope(child: KrishokApp()));
}

class KrishokApp extends ConsumerWidget {
  const KrishokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'KrishiBondhu',
      debugShowCheckedModeBanner: false,
      routes: AppRouter.routes,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return authAsync.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => const _SplashScreen(),
      data: (authState) {
        if (authState.isAuthenticated) {
          return AppRouter.routes[AppRouter.home]!(context);
        }
        return AppRouter.routes[AppRouter.login]!(context);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.jpeg',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Color(0xFF2E7D32),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
