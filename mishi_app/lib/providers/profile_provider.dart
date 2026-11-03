import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/api/profile_service.dart';
import 'auth_provider.dart';

final profileProvider = FutureProvider.autoDispose<Profile>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  if (user == null || user.id.isEmpty) {
    throw Exception('未登录');
  }
  final service = ref.watch(profileServiceProvider);
  return service.fetchProfile(user.id);
});
