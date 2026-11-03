import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../providers/checkin_provider.dart';

class CheckinHistoryPage extends ConsumerWidget {
  const CheckinHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(checkinHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的打卡')),
      body: historyAsync.when(
        data: (data) {
          if (data.checkins.isEmpty) {
            return const Center(child: Text('还没有打卡记录'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(checkinHistoryProvider),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _statCard('总打卡', data.total),
                      const SizedBox(width: 8),
                      _statCard('地点', data.totalPois),
                      const SizedBox(width: 8),
                      _statCard('城市', data.totalCities),
                    ],
                  ),
                ),
                ...data.checkins.map(
                  (item) => ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(item.poiName),
                    subtitle: Text(
                      '${item.poemTitle}\n${item.checkinTime.toLocal()}',
                    ),
                    isThreeLine: true,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败: ${errorMessageOf(err)}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(checkinHistoryProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
