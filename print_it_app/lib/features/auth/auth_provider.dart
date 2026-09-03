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
  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final apiClient = ref.read(apiProvider);
      try {
        final res = await apiClient.get('/auth/profile');
        if (res.statusCode == 200) {
          state = state.copyWith(user: res.data['user'] ?? res.data);
          ref.read(notificationServiceProvider).initialize();
        } else {
          await prefs.remove('token');
          state = AuthState();
        }
      } catch (e) {
        // Leave token intact or handle offline
      }
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        state = state.copyWith(isLoading: false, user: res.data['user']);
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
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
        }
        state = state.copyWith(isLoading: false, user: res.data['user']);
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
      final res = await apiClient.put('/auth/profile', data: {
        'full_name': fullName,
        'phone': phone,
        'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });

      if (res.statusCode == 200) {
        final updatedUser = res.data['user'] ?? res.data;
        state = state.copyWith(isLoading: false, user: updatedUser);
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        state = state.copyWith(isLoading: false, user: res.data['user']);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        state = state.copyWith(isLoading: false, user: res.data['user']);
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
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          state = state.copyWith(isLoading: false, user: res.data['user']);
          ref.read(notificationServiceProvider).initialize();
        }
      }
    } catch (_) {}
  }
}
