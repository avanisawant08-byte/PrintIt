import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final supportTicketsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(apiProvider);
  final res = await dio.get('/support/tickets');
  if (res.statusCode == 200) {
    return res.data as List<dynamic>;
  } else {
    throw Exception('Failed to load tickets');
  }
});

final ticketDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, ticketId) async {
  final dio = ref.read(apiProvider);
  final res = await dio.get('/support/tickets/$ticketId');
  if (res.statusCode == 200) {
    return res.data as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load ticket details');
  }
});
