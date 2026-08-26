import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio dio;
  static String currentBaseUrl = 'http://192.168.1.108:3000/api';
  static String get baseUrl => currentBaseUrl;
  bool _isDiscovering = false;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: currentBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
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
        if (_isConnectionFailure(e) && !_isDiscovering) {
          debugPrint('ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã‚Â¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã‚Â¯Ãƒâ€šÃ‚Â¸Ãƒâ€šÃ‚Â Connection failed to ${dio.options.baseUrl}. Attempting server auto-discovery...');
          final workingUrl = await autoDiscoverBackend();
          if (workingUrl != null) {
            debugPrint('ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ Server auto-discovered at: $workingUrl');
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
    if (_isDiscovering) return null;
    _isDiscovering = true;

    try {
      final List<String> candidateUrls = [
        'http://10.108.45.102:3000/api',
        'http://Sawant.local:3000/api',
        if (currentBaseUrl != 'http://10.108.45.102:3000/api' && currentBaseUrl != 'http://Sawant.local:3000/api') currentBaseUrl,
        'http://192.168.1.108:3000/api',
        'http://127.0.0.1:3000/api',
        'http://10.0.2.2:3000/api',
      ];

      for (final url in candidateUrls) {
        if (await _testUrl(url)) {
          await updateServerUrl(url);
          _isDiscovering = false;
          return url;
        }
      }

      final List<String> commonSubnets = [
        '192.168.137', // Windows Mobile Hotspot
        '172.20.10',   // iPhone Hotspot
        '192.168.43',  // Android Hotspot
        '192.168.1', 
        '192.168.0', 
        '10.0.0',
        '10.108.45'
      ];

      for (final subnet in commonSubnets) {
        // Test gateway and a few common IPs first
        List<String> fastTestUrls = [
          'http://$subnet.1:3000/api',
          'http://$subnet.100:3000/api',
          'http://$subnet.108:3000/api'
        ];

        for (final url in fastTestUrls) {
          if (candidateUrls.contains(url)) continue;
          if (await _testUrl(url)) {
            await updateServerUrl(url);
            _isDiscovering = false;
            return url;
          }
        }

        // Parallel scan for a range of IPs
        List<Future<String?>> futures = [];
        for (int i = 2; i <= 254; i++) {
          if (i == 100 || i == 108) continue;
          final testUrl = 'http://$subnet.$i:3000/api';
          if (candidateUrls.contains(testUrl)) continue;
          
          futures.add(() async {
            if (await _testUrl(testUrl)) {
              return testUrl;
            }
            return null;
          }());
        }

        // Wait for any successful discovery in this subnet
        // We chunk them to avoid too many open sockets
        for (int i = 0; i < futures.length; i += 50) {
          final chunk = futures.sublist(i, (i + 50 > futures.length) ? futures.length : i + 50);
          final results = await Future.wait(chunk);
          final found = results.firstWhere((r) => r != null, orElse: () => null);
          if (found != null) {
            await updateServerUrl(found);
            _isDiscovering = false;
            return found;
          }
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
