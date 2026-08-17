import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      debugPrint('🔵 LOGIN: Attempting POST to ${ApiClient.baseUrl}/auth/login');
      debugPrint('🔵 LOGIN: email=$email');
      final res = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      debugPrint('🟢 LOGIN: Response status=${res.statusCode}');
      debugPrint('🟢 LOGIN: Response data=${res.data}');

      if (res.statusCode == 200) {
        final token = res.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        state = state.copyWith(isLoading: false, user: res.data['user']);
        ref.read(notificationServiceProvider).initialize();
        return true;
      } else {
        final errorMsg = res.data is Map ? res.data['error'] ?? 'Login failed' : 'Login failed (${res.statusCode})';
        debugPrint('🟡 LOGIN: Non-200 status: ${res.statusCode} body=${res.data}');
        state = state.copyWith(isLoading: false, error: errorMsg);
      }
    } catch (e, stackTrace) {
      String errorMsg = 'Login failed. Please check credentials.';
      if (e is DioException) {
        debugPrint('🔴 LOGIN ERROR: DioException type=${e.type}');
        debugPrint('🔴 LOGIN ERROR: message=${e.message}');
        debugPrint('🔴 LOGIN ERROR: response status=${e.response?.statusCode}');
        debugPrint('🔴 LOGIN ERROR: response data=${e.response?.data}');
        debugPrint('🔴 LOGIN ERROR: requestUrl=${e.requestOptions.uri}');
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Connection timed out. Server not reachable.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'Cannot connect to server at ${ApiClient.baseUrl}';
        } else if (e.response != null) {
          errorMsg = e.response?.data?['error'] ?? 'Login failed (${e.response?.statusCode})';
        }
      } else {
        debugPrint('🔴 LOGIN ERROR: Unknown error type=${e.runtimeType} message=$e');
        debugPrint('🔴 LOGIN STACKTRACE: $stackTrace');
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
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

  Future<bool> updateProfile({String? fullName, String? phone, String? avatarUrl, String? email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiProvider);
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (email != null) data['email'] = email;
      
      final res = await apiClient.put('/auth/profile', data: data);
      
      if (res.statusCode == 200) {
        state = state.copyWith(isLoading: false, user: res.data['user']);
        return true;
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (e is DioException && e.response != null) {
         state = state.copyWith(isLoading: false, error: e.response?.data?['error'] ?? 'Failed to update profile.');
      } else {
         state = state.copyWith(isLoading: false, error: 'Failed to update profile.');
      }
    }
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    state = AuthState();
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: '322993568107-dpgb4hsmat85kugnbeqjpltrdd4hbn3c.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken != null) {
        final apiClient = ref.read(apiProvider);
        final res = await apiClient.post('/auth/google', data: {
          'firebase_token': firebaseToken,
        });

        if (res.statusCode == 200) {
          final token = res.data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          state = state.copyWith(isLoading: false, user: res.data['user']);
          ref.read(notificationServiceProvider).initialize();
          return true;
        } else {
          state = state.copyWith(isLoading: false, error: res.data['error'] ?? 'Google login failed');
          return false;
        }
      } else {
         state = state.copyWith(isLoading: false, error: 'Could not retrieve Firebase token.');
         return false;
      }
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
      String errorMsg = 'Failed to sign in with Google: $e';
      if (e is DioException && e.response != null) {
        errorMsg = e.response?.data?['error'] ?? 'Google login failed (${e.response?.statusCode})';
      } else if (e is PlatformException) {
        errorMsg = 'Google Sign-In failed: ${e.message}';
      } else if (e is FirebaseAuthException) {
        errorMsg = 'Firebase Auth failed: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }
}
