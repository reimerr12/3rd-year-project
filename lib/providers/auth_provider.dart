import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;

  const AuthState({required this.status, this.user});

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null;

  const AuthState.authenticated(AppUser u)
      : status = AuthStatus.authenticated,
        user = u;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<AuthState> {
  late SupabaseService _service;
  StreamSubscription<AppUser?>? _authSub;

  // Flag to prevent the stream listener from overwriting state
  // while build() is still resolving the initial user.
  bool _buildComplete = false;

  @override
  Future<AuthState> build() async {
    _service = SupabaseService();
    _buildComplete = false;

    await _authSub?.cancel();

    _authSub = _service.authStateChanges.listen((user) {
      if (!_buildComplete) return;
      if (user != null) {
        state = AsyncData(AuthState.authenticated(user));
      } else {
        state = const AsyncData(AuthState.unauthenticated());
      }
    });

    final resolved = await _resolveCurrentUser();
    _buildComplete = true;
    return resolved;
  }

  Future<AuthState> _resolveCurrentUser() async {
    try {
      final user = await _service.currentAppUser();
      if (user != null) return AuthState.authenticated(user);
      return const AuthState.unauthenticated();
    } catch (_) {
      return const AuthState.unauthenticated();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final resolved = await _resolveCurrentUser();
    state = AsyncData(resolved);
  }

  Future<void> signOut() async {
    try {
      await _service.signOut();
    } catch (_) {}
    state = const AsyncData(AuthState.unauthenticated());
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// True while the cold-start session check is in flight — show splash/loading.
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).maybeWhen(
        loading: () => true,
        orElse: () => false,
      );
});

/// The currently logged-in AppUser, or null if unauthenticated.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).valueOrNull?.user;
});

/// True if the user has a valid, authenticated session.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull?.isAuthenticated ?? false;
});
