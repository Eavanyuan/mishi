import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checkin_history.dart';
import '../services/api/checkin_service.dart';

final checkinHistoryProvider = FutureProvider.autoDispose<CheckinHistoryResponse>((ref) async {
  final service = ref.watch(checkinServiceProvider);
  return service.fetchHistory(limit: 50, offset: 0);
});
