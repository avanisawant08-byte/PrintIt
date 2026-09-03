import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio dio;
  static const String defaultCloudBackend = 'https://printit-zaf4.onrender.com/api';
  static const String envApiUrl = String.fromEnvironment('API_URL');
  static String currentBaseUrl = envApiUrl.isNotEmpty
      ? envApiUrl
      : (kIsWeb
          ? (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1'
              ? 'http://localhost:3000/api'
              : (Uri.base.host.startsWith('192.') || Uri.base.host.startsWith('10.') || Uri.base.host.startsWith('172.')
                  ? 'http://${Uri.base.host}:3000/api'
                  : defaultCloudBackend))
          : defaultCloudBackend);
  static String get baseUrl => currentBaseUrl;
  bool _isDiscovering = false;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: currentBaseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _loadSavedServerUrl();

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (!kIsWeb && _isConnectionFailure(e) && !_isDiscovering) {
          debugPrint('⚠️ Connection failed to ${dio.options.baseUrl}. Attempting server auto-discovery...');
          final workingUrl = await autoDiscoverBackend();
          if (workingUrl != null) {
            debugPrint('✅ Server auto-discovered at: $workingUrl');
            final opts = e.requestOptions;
            opts.baseUrl = workingUrl;
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {}
          }
        }
        return handler.next(e);
      },
    ));
  }

  static bool _isConnectionFailure(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Future<void> _loadSavedServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('saved_server_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        currentBaseUrl = savedUrl;
        dio.options.baseUrl = savedUrl;
      }
    } catch (_) {}
  }

  /// Automatically discover working backend server on local WiFi or mDNS
  Future<String?> autoDiscoverBackend() async {
    if (_isDiscovering || kIsWeb) return null;
    _isDiscovering = true;

    try {
      final List<String> candidateUrls = [
        'http://localhost:3000/api',
        'http://127.0.0.1:3000/api',
        'http://192.168.1.111:3000/api',
        if (currentBaseUrl != 'http://localhost:3000/api') currentBaseUrl,
      ];

      for (final url in candidateUrls) {
        if (await _testUrl(url)) {
          await updateServerUrl(url);
          _isDiscovering = false;
          return url;
        }
      }
    } catch (e) {
      debugPrint('Error in autoDiscoverBackend: $e');
    } finally {
      _isDiscovering = false;
    }
    return null;
  }

  Future<bool> _testUrl(String url) async {
    try {
      final probeDio = Dio(BaseOptions(
        connectTimeout: const Duration(milliseconds: 1200),
        receiveTimeout: const Duration(milliseconds: 1200),
      ));
      final res = await probeDio.get('$url/public/shops');
      return res.statusCode != null && res.statusCode! < 500;
    } catch (_) {
      return false;
    }
  }

  /// Manually update and save backend server URL
  Future<void> updateServerUrl(String newUrl) async {
    String formattedUrl = newUrl.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'http://$formattedUrl';
    }
    if (!formattedUrl.endsWith('/api')) {
      if (formattedUrl.endsWith('/')) {
        formattedUrl = '${formattedUrl}api';
      } else {
        formattedUrl = '$formattedUrl/api';
      }
    }

    currentBaseUrl = formattedUrl;
    dio.options.baseUrl = formattedUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_server_url', formattedUrl);
    debugPrint('Saved new API baseUrl: $formattedUrl');
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await dio.delete(path, data: data);
  }
}
