import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/services/notification_service.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, Map<String, dynamic>? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkLoginStatus();
    return AuthState();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final apiClient = ref.read(apiProvider);
        final res = await apiClient.get('/auth/me');
        if (res.statusCode == 200) {
          state = state.copyWith(user: res.data);
          ref.read(notificationServiceProvider).initialize();
        }
      } catch (e) {
        prefs.remove('token');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiProvider);
      final res = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200) {
        final token = res.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        state = state.copyWith(isLoading: false, user: res.data['user']);
        ref.read(notificationServiceProvider).initialize();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed. Please check credentials.');
    }
    return false;
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiProvider);
      final res = await apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });

      if (res.statusCode == 201) {
        final token = res.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        state = state.copyWith(isLoading: false, user: res.data['user']);
        ref.read(notificationServiceProvider).initialize();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed. Email might already be in use.');
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = AuthState();
  }
}
