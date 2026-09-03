import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final shopsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.read(apiProvider);
  final response = await apiClient.get('/public/shops');
  if (response.statusCode == 200) {
    return response.data as List<dynamic>;
  } else {
    throw Exception('Failed to load shops');
  }
});
