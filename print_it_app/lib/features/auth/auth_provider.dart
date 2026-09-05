import 'dart:convert';
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

const String _kGoogleClientId = '322993568107-dpgb4hsmat85kugnbeqjpltrdd4hbn3c.apps.googleusercontent.com';

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
  static Map<String, dynamic>? initialCachedUser;

  @override
  AuthState build() {
    // Instantly hydrate session if initialCachedUser was loaded at app startup
    if (initialCachedUser != null) {
      Future.microtask(() => checkAuth());
      return AuthState(user: initialCachedUser);
    }

    // Schedule eager checkAuth to restore session from local storage immediately
    Future.microtask(() => checkAuth());
    return AuthState();
  }

  Future<void> _saveSession(String token, Map<String, dynamic>? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      if (user != null) {
        await prefs.setString('user_data', jsonEncode(user));
        initialCachedUser = user;
      }
    } catch (e) {
      debugPrint('Error saving auth session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_data');
      initialCachedUser = null;
    } catch (e) {
      debugPrint('Error clearing auth session: $e');
    }
  }

  void setUser(Map<String, dynamic> user) {
    state = state.copyWith(user: user);
    initialCachedUser = user;
  }

  Future<void> checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final cachedUserJson = prefs.getString('user_data');

      // 1. Immediately hydrate local user if not already populated in state
      if (token != null && cachedUserJson != null && state.user == null) {
        try {
          final localUser = jsonDecode(cachedUserJson) as Map<String, dynamic>;
          state = state.copyWith(user: localUser);
          initialCachedUser = localUser;
        } catch (_) {}
      }

      // 2. Validate token and refresh profile against server in background
      if (token != null) {
        final apiClient = ref.read(apiProvider);
        try {
          var res = await apiClient.get('/auth/profile');
          if (res.statusCode != 200) {
            res = await apiClient.get('/auth/me');
          }

          if (res.statusCode == 200) {
            final rawData = res.data;
            final Map<String, dynamic>? userData = (rawData is Map
                ? (rawData['user'] is Map ? rawData['user'] : rawData)
                : null) as Map<String, dynamic>?;
            if (userData != null) {
              state = state.copyWith(user: userData);
              await prefs.setString('user_data', jsonEncode(userData));
              initialCachedUser = userData;
              ref.read(notificationServiceProvider).initialize();
            }
          } else if (res.statusCode == 401 || res.statusCode == 403) {
            // Only wipe token if backend explicitly rejected authentication
            await _clearSession();
            state = AuthState();
          }
        } catch (e) {
          // Offline or network error - keep token and existing cached session!
          debugPrint('Server session validation skipped (offline/error): $e');
        }
      }
    } catch (err) {
      debugPrint('checkAuth error: $err');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final apiClient = ref.read(apiProvider);
    try {
      final res = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200) {
        final token = res.data['token'];
        final user = (res.data['user'] is Map ? Map<String, dynamic>.from(res.data['user']) : null);
        if (token != null) {
          await _saveSession(token, user);
        }
        state = state.copyWith(isLoading: false, user: user);
        ref.read(notificationServiceProvider).initialize();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.data['error'] ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      String errorMsg = 'An unexpected error occurred';
      if (e is DioException && e.response != null) {
        errorMsg = e.response?.data?['error'] ?? 'Login failed (${e.response?.statusCode})';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String fullName, [
    String? phone,
  ]) async {
    state = state.copyWith(isLoading: true, error: null);
    final apiClient = ref.read(apiProvider);
    try {
      final res = await apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        final token = res.data['token'];
        final user = (res.data['user'] is Map ? Map<String, dynamic>.from(res.data['user']) : null);
        if (token != null) {
          await _saveSession(token, user);
        }
        state = state.copyWith(isLoading: false, user: user);
        ref.read(notificationServiceProvider).initialize();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.data['error'] ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      String errorMsg = 'Registration failed';
      if (e is DioException && e.response != null) {
        errorMsg = e.response?.data?['error'] ?? 'Registration failed (${e.response?.statusCode})';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String email,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final apiClient = ref.read(apiProvider);
    try {
      final payload = <String, dynamic>{
        'full_name': fullName,
        'phone': phone,
        'email': email,
      };
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
      final res = await apiClient.put('/auth/profile', data: payload);

      if (res.statusCode == 200) {
        final rawUser = res.data['user'] ?? res.data;
        final updatedUser = rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;
        if (updatedUser != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(updatedUser));
          initialCachedUser = updatedUser;
          state = state.copyWith(isLoading: false, user: updatedUser);
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.data['error'] ?? 'Profile update failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update profile');
      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    final apiClient = ref.read(apiProvider);
    try {
      final res = await apiClient.post('/auth/send-otp', data: {'phone': phone});
      if (res.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: res.data['error'] ?? 'Failed to send OTP',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send OTP');
    }
    return false;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    final apiClient = ref.read(apiProvider);
    try {
      final res = await apiClient.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });
      if (res.statusCode == 200) {
        final token = res.data['token'];
        final user = (res.data['user'] is Map ? Map<String, dynamic>.from(res.data['user']) : null);
        if (token != null) {
          await _saveSession(token, user);
        }
        state = state.copyWith(isLoading: false, user: user);
        ref.read(notificationServiceProvider).initialize();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: res.data['error'] ?? 'Invalid OTP',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'OTP verification failed');
    }
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<void> logout() async {
    await _clearSession();
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? _kGoogleClientId : null,
        serverClientId: _kGoogleClientId,
      );
      await googleSignIn.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    state = AuthState();
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? _kGoogleClientId : null,
        serverClientId: _kGoogleClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
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
          final user = (res.data['user'] is Map ? Map<String, dynamic>.from(res.data['user']) : null);
          if (token != null) {
            await _saveSession(token, user);
          }
          state = state.copyWith(isLoading: false, user: user);
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

  ConfirmationResult? _webConfirmationResult;
  String? _mobileVerificationId;

  /// Send SMS OTP to 10-digit Indian phone number
  Future<bool> sendPhoneOtp(String rawPhone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = cleanDigits.length == 10
          ? '+91$cleanDigits'
          : (cleanDigits.startsWith('91') ? '+$cleanDigits' : '+$cleanDigits');

      if (kIsWeb) {
        _webConfirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(formattedPhone);
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _loginWithFirebaseCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            state = state.copyWith(isLoading: false, error: e.message ?? 'OTP verification failed');
          },
          codeSent: (String verId, int? resendToken) {
            _mobileVerificationId = verId;
            state = state.copyWith(isLoading: false);
          },
          codeAutoRetrievalTimeout: (String verId) {
            _mobileVerificationId = verId;
          },
        );
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error sending phone OTP: $e');
      String msg = 'Failed to send OTP: $e';
      if (e is FirebaseAuthException) {
        msg = e.message ?? 'OTP sending failed';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  /// Verify 6-digit SMS OTP and login / create account
  Future<bool> verifyPhoneOtpAndLogin(String smsCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        if (_webConfirmationResult == null) {
          state = state.copyWith(isLoading: false, error: 'Please request OTP first');
          return false;
        }
        userCredential = await _webConfirmationResult!.confirm(smsCode.trim());
      } else {
        if (_mobileVerificationId == null) {
          state = state.copyWith(isLoading: false, error: 'Verification session expired. Please resend OTP.');
          return false;
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: _mobileVerificationId!,
          smsCode: smsCode.trim(),
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) {
        state = state.copyWith(isLoading: false, error: 'Could not obtain authentication token');
        return false;
      }

      final apiClient = ref.read(apiProvider);
      final res = await apiClient.post('/auth/phone', data: {
        'firebase_token': firebaseToken,
      });

      if (res.statusCode == 200) {
        final token = res.data['token'];
        final user = (res.data['user'] is Map ? Map<String, dynamic>.from(res.data['user']) : null);
        if (token != null) {
          await _saveSession(token, user);
        }
        state = state.copyWith(isLoading: false, user: user);
        ref.read(notificationServiceProvider).initialize();
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: res.data['error'] ?? 'Phone login failed');
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      String msg = 'Invalid OTP: $e';
      if (e is FirebaseAuthException) {
        msg = e.message ?? 'Invalid OTP code entered';
      } else if (e is DioException && e.response != null) {
        msg = e.response?.data?['error'] ?? 'Server error during phone login';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> _loginWithFirebaseCredential(AuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken != null) {
        final apiClient = ref.read(apiProvider);
        final res = await apiClient.post('/auth/phone', data: {
          'firebase_token': firebaseToken,
        });
        if (res.statusCode == 200) {
          final token = res.data['token'];
          final user = (res.data['user'] is Map ? Map<String, dynamic>.from(res.data['user']) : null);
          if (token != null) {
            await _saveSession(token, user);
          }
          state = state.copyWith(isLoading: false, user: user);
          ref.read(notificationServiceProvider).initialize();
        }
      }
    } catch (_) {}
  }
}
