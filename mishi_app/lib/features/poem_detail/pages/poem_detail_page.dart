import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/network/api_error.dart';
import '../../../providers/checkin_provider.dart';
import '../../../providers/poem_provider.dart';
import '../../../providers/poem_state.dart';
import '../../../providers/profile_provider.dart';
import '../../../models/poem.dart';
import '../../../models/ai_job.dart';
import '../../../services/api/ai_service.dart';
import '../../../services/api/checkin_service.dart';
import '../../../core/location/location_service.dart';

class PoemDetailPage extends ConsumerStatefulWidget {
  final String poemId;

  const PoemDetailPage({super.key, required this.poemId});

  @override
  ConsumerState<PoemDetailPage> createState() => _PoemDetailPageState();
}

class _PoemDetailPageState extends ConsumerState<PoemDetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioLoading = false;
  bool _isCheckingIn = false;
  bool _isGeneratingInterpretation = false;
  bool _isGeneratingTTS = false;
  bool _isGeneratingVideo = false;
  String? _currentAudioUrl;
  AILatestInterpretationSnapshot? _latestInterpretationSnapshot;
  AIJob? _latestTtsJob;
  AIJob? _latestVideoJob;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
    _audioPlayer.positionStream.listen((_) {
      if (mounted) setState(() {});
    });
    // 加载诗词详情
    Future.microtask(() {
      ref.read(poemProvider.notifier).fetchPoemDetail(widget.poemId);
      _loadLatestInterpretation();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poemState = ref.watch(poemProvider);
    Poem? poem;
    for (final item in poemState.poems) {
      if (item.id == widget.poemId) {
        poem = item;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('诗歌详情')),
      body: poem != null ? _buildPoemDetail(poem) : _buildLoading(poemState),
    );
  }

  Widget _buildLoading(PoemState state) {
    if (state.isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('加载失败'),
            ElevatedButton(
              onPressed: () {
                ref.read(poemProvider.notifier).fetchPoemDetail(widget.poemId);
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildPoemDetail(Poem poem) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poem.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${poem.author} · ${poem.dynasty}',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ...poem.content.map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                line,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (poem.interpretations != null && poem.interpretations!.isNotEmpty)
            ..._buildSection('解读', poem.interpretations!),
          if (poem.bestSeasons != null && poem.bestSeasons!.isNotEmpty)
            ..._buildSection('最佳观赏季节', poem.bestSeasons!),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isCheckingIn ? null : () => _checkin(poem),
            icon: _isCheckingIn
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('在此打卡'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isGeneratingInterpretation
                    ? null
                    : () => _generateInterpretation(poem),
                icon: _isGeneratingInterpretation
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_stories_outlined),
                label: const Text('AI解读'),
              ),
              OutlinedButton.icon(
                onPressed: _isGeneratingTTS ? null : () => _generateTTS(poem),
                icon: _isGeneratingTTS
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.record_voice_over_outlined),
                label: const Text('AI诵读'),
              ),
              OutlinedButton.icon(
                onPressed: _isGeneratingVideo
                    ? null
                    : () => _generateStoryVideo(poem),
                icon: _isGeneratingVideo
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.movie_creation_outlined),
                label: const Text('故事动画'),
              ),
            ],
          ),
          if (poem.hasAudio &&
              poem.audioUrl != null &&
              poem.audioUrl!.isNotEmpty)
            _buildAudioPlayer(poem),
          if (_latestInterpretationSnapshot?.hasInterpretation == true)
            _buildInterpretationCard(_latestInterpretationSnapshot!),
          if (_latestTtsJob?.isSuccess == true)
            _buildJobResultCard(
              title: '最新 AI 诵读',
              job: _latestTtsJob!,
              body: _latestTtsJob!.audioUrl?.isNotEmpty == true
                  ? SelectableText(_latestTtsJob!.audioUrl!)
                  : const Text('音频已生成'),
            ),
          if (_latestVideoJob?.isSuccess == true)
            _buildJobResultCard(
              title: '最新故事动画',
              job: _latestVideoJob!,
              body: _latestVideoJob!.videoUrl?.isNotEmpty == true
                  ? SelectableText(_latestVideoJob!.videoUrl!)
                  : const Text('视频已生成'),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSection(String title, List<String> items) {
    return [
      const SizedBox(height: 24),
      Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text('• $item'),
        ),
      ),
    ];
  }

  Widget _buildAudioPlayer(Poem poem) {
    final duration = _audioPlayer.duration;
    final position = _audioPlayer.position;
    final hasDuration = duration != null && duration.inMilliseconds > 0;
    final progress = hasDuration
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.audiotrack, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('音频朗诵'),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: progress),
              ],
            ),
          ),
          IconButton(
            onPressed: _isAudioLoading ? null : () => _toggleAudio(poem),
            icon: _isAudioLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_audioPlayer.playing ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationCard(AILatestInterpretationSnapshot snapshot) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '最新 AI 解读',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if ((snapshot.provider ?? '').isNotEmpty)
                Text(
                  snapshot.provider!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(snapshot.interpretation ?? ''),
          const SizedBox(height: 8),
          Text(
            '任务号：${snapshot.jobId ?? "-"}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildJobResultCard({
    required String title,
    required AIJob job,
    required Widget body,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                job.statusLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'provider: ${job.provider.isEmpty ? "-" : job.provider}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          body,
          if (job.thumbnailUrl != null && job.thumbnailUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText('thumbnail: ${job.thumbnailUrl}'),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleAudio(Poem poem) async {
    final url = poem.audioUrl;
    if (url == null || url.isEmpty) return;

    try {
      if (_currentAudioUrl != url) {
        setState(() {
          _isAudioLoading = true;
        });
        await _audioPlayer.setUrl(url);
        _currentAudioUrl = url;
      }

      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('音频播放失败，请稍后重试')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
      }
    }
  }

  Future<void> _loadLatestInterpretation() async {
    try {
      final aiService = ref.read(aiServiceProvider);
      final snapshot = await aiService.getLatestInterpretation(widget.poemId);
      if (!mounted || snapshot == null || !snapshot.hasInterpretation) {
        return;
      }
      setState(() {
        _latestInterpretationSnapshot = snapshot;
      });
    } catch (_) {
      // 页面加载时的历史回填失败不应打断主流程。
    }
  }

  Future<AIJob> _createAndWaitAIJob(
    Poem poem, {
    required String jobType,
    String? style,
    String? voice,
    String? text,
    int? seconds,
  }) async {
    final aiService = ref.read(aiServiceProvider);
    final jobId = await aiService.createJob(
      jobType: jobType,
      poemId: poem.id,
      style: style,
      voice: voice,
      text: text,
      seconds: seconds,
    );
    return aiService.waitForJob(jobId);
  }

  Future<void> _generateInterpretation(Poem poem) async {
    setState(() {
      _isGeneratingInterpretation = true;
    });
    try {
      final job = await _createAndWaitAIJob(
        poem,
        jobType: 'interpretation',
        style: 'cinematic',
      );
      if (!mounted) return;
      if (!job.isSuccess) {
        throw Exception(job.userFacingFailureMessage);
      }
      final text = job.text ?? '';
      if (text.isEmpty) {
        throw Exception('AI 解读结果为空');
      }
      setState(() {
        _latestInterpretationSnapshot = AILatestInterpretationSnapshot(
          poemId: poem.id,
          provider: job.provider,
          interpretation: text,
          jobId: job.jobId,
          finishedAt: DateTime.now(),
        );
      });
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('AI解读'),
          content: SingleChildScrollView(child: Text(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI解读失败：${errorMessageOf(e)}')));
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingInterpretation = false;
        });
      }
    }
  }

  Future<void> _generateTTS(Poem poem) async {
    setState(() {
      _isGeneratingTTS = true;
    });
    try {
      final job = await _createAndWaitAIJob(
        poem,
        jobType: 'tts_reading',
        voice: 'warm_female',
        style: 'poetry',
        text: poem.content.join('，'),
      );
      if (!mounted) return;
      if (!job.isSuccess) {
        throw Exception(job.userFacingFailureMessage);
      }
      final audioUrl = job.audioUrl ?? '';
      if (audioUrl.isEmpty) {
        throw Exception('AI 诵读音频地址为空');
      }
      setState(() {
        _latestTtsJob = job;
      });
      setState(() {
        _isAudioLoading = true;
      });
      await _audioPlayer.setUrl(audioUrl);
      _currentAudioUrl = audioUrl;
      await _audioPlayer.play();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI诵读已开始播放')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI诵读失败：${errorMessageOf(e)}')));
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingTTS = false;
          _isAudioLoading = false;
        });
      }
    }
  }

  Future<void> _generateStoryVideo(Poem poem) async {
    setState(() {
      _isGeneratingVideo = true;
    });
    try {
      final job = await _createAndWaitAIJob(
        poem,
        jobType: 'story_video',
        style: 'ink',
        seconds: 15,
      );
      if (!mounted) return;
      if (!job.isSuccess) {
        throw Exception(job.userFacingFailureMessage);
      }
      final videoUrl = job.videoUrl ?? '';
      if (videoUrl.isEmpty) {
        throw Exception('故事动画地址为空');
      }
      setState(() {
        _latestVideoJob = job;
      });
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('故事动画已生成'),
          content: SelectableText(videoUrl),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('故事动画失败：${errorMessageOf(e)}')));
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingVideo = false;
        });
      }
    }
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
      _isCheckingIn = true;
    });
    try {
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
          _isCheckingIn = false;
        });
      }
    }
  }
}
