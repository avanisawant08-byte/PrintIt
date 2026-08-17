import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final walletProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(apiProvider);
  final res = await dio.get('/wallet');
  if (res.statusCode == 200) {
    return res.data;
  } else {
    throw Exception('Failed to load wallet data');
  }
});
