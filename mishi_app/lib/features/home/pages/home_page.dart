import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/api_error.dart';
import '../../../providers/poem_provider.dart';
import '../../../providers/poem_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/checkin_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../models/poem.dart';
import '../../../services/api/checkin_service.dart';
import '../../../core/location/location_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String? _checkingInPoemId;

  @override
  void initState() {
    super.initState();
    // 初始化加载推荐诗词
    Future.microtask(() {
      ref.read(poemProvider.notifier).fetchRecommendations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poemState = ref.watch(poemProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('觅诗'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                ref.read(poemProvider.notifier).searchPoems(value);
              },
              decoration: InputDecoration(
                hintText: '搜索诗词标题/作者/内容',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(poemProvider.notifier).fetchRecommendations();
                  },
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (authState.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                _showUserMenu(context);
              },
            ),
        ],
      ),
      body: _buildBody(poemState),
    );
  }

  Widget _buildBody(PoemState state) {
    return state.when(
      initial: () => const Center(child: CircularProgressIndicator()),
      loading: () => const Center(child: CircularProgressIndicator()),
      loaded: (poems, recommendations, hasMore, totalCount, isLoadingMore) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _searchController.text.trim().isEmpty ? '今日推荐' : '搜索结果',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final poem = recommendations[index];
                  return _buildPoemCard(poem);
                },
              ),
            ),
          ],
        );
      },
      error: (message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $message'),
            ElevatedButton(
              onPressed: () {
                ref.read(poemProvider.notifier).fetchRecommendations();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoemCard(Poem poem) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poem.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${poem.author} · ${poem.dynasty}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              poem.content.take(2).join('\n'),
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (poem.id.isNotEmpty) {
                      context.push('/poem/${poem.id}');
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('诗词详情暂不可用')));
                    }
                  },
                  child: const Text('查看详情'),
                ),
                ElevatedButton(
                  onPressed: _checkingInPoemId == poem.id
                      ? null
                      : () => _checkin(poem),
                  child: _checkingInPoemId == poem.id
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('打卡'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkin(Poem poem) async {
    final poiId = poem.relatedPoiId;
    if (poiId == null || poiId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('该诗词暂无可打卡地点')));
      return;
    }

    setState(() {
      _checkingInPoemId = poem.id;
    });
    try {
      final platformName = Theme.of(context).platform.name;
      final Position pos = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      final result = await ref
          .read(checkinServiceProvider)
          .submitCheckin(
            poiId: poiId,
            poemId: poem.id,
            latitude: pos.latitude,
            longitude: pos.longitude,
            deviceInfo: {'platform': platformName},
          );
      ref.invalidate(checkinHistoryProvider);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打卡成功：${result.poiName}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打卡失败：${errorMessageOf(e)}')));
    } finally {
      if (mounted) {
        setState(() {
          _checkingInPoemId = null;
        });
      }
    }
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(ref.read(authProvider).user?.username ?? '用户'),
              subtitle: Text(ref.read(authProvider).user?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('个人主页'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
