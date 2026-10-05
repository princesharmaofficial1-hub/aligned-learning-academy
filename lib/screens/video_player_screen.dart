import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/course.dart';
import '../models/course_document.dart';
import '../models/lecture.dart';
import '../providers/course_provider.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sources_credits_dialog.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Course course;
  final Lecture initialLecture;

  const VideoPlayerScreen({
    super.key,
    required this.course,
    required this.initialLecture,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  late Lecture _currentLecture;
  VideoPlayerController? _controller;
  YoutubePlayerController? _youtubeController;
  StreamSubscription<YoutubePlayerValue>? _youtubeSubscription;
  Timer? _youtubeProgressTimer;
  Duration _youtubePosition = Duration.zero;
  bool _youtubeProgressPollActive = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFullscreen = false;
  bool _isChangingFullscreen = false;
  int _playerLoadId = 0;
  int _lastProgressSavedSecond = -1;
  bool _completionProgressSaved = false;
  String? _autoAdvancedLectureId;

  // Player settings & behaviors
  double _currentSpeed = 1.0;
  bool _showControls = true;
  bool _isLocked = false;
  bool _autoPlayNext = true;
  BoxFit _videoFit = BoxFit.contain; // contain, cover, fill
  Timer? _hideControlsTimer;
  Timer? _sleepTimer;
  String _sleepTimerLabel = 'Off';

  // Double tap feedback
  bool _showSeekLeftIndicator = false;
  bool _showSeekRightIndicator = false;

  late TabController _tabController;
  final TextEditingController _noteInputController = TextEditingController();

  // Equalizer animation for playlist
  late AnimationController _eqController;

  @override
  void initState() {
    super.initState();
    _currentLecture = widget.initialLecture;
    _tabController = TabController(length: 5, vsync: this);

    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initializePlayer(_currentLecture.videoUrl);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (!_showControls || _isLocked) return;
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  Future<void> _initializePlayer(String url) async {
    final loadId = ++_playerLoadId;
    final previousController = _controller;
    final previousYoutubeController = _youtubeController;
    _controller = null;
    _youtubeController = null;
    _youtubeProgressTimer?.cancel();
    _youtubeProgressTimer = null;
    unawaited(_youtubeSubscription?.cancel());
    _youtubeSubscription = null;
    if (previousController != null) {
      previousController.removeListener(_handlePlayerListener);
    }

    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
      _showControls = true;
    });

    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';
    try {
      await previousController?.dispose();
      await previousYoutubeController?.close();
      if (!mounted || loadId != _playerLoadId) return;

      if ((host == 'youtube.com' ||
              host.endsWith('.youtube.com') ||
              host == 'youtu.be') &&
          YoutubePlayerController.convertUrlToId(url) == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'This YouTube video URL is invalid.';
        });
        return;
      }

      final youtubeVideoId = YoutubePlayerController.convertUrlToId(url);
      if (youtubeVideoId != null) {
        final controller = YoutubePlayerController.fromVideoId(
          videoId: youtubeVideoId,
          autoPlay: true,
          params: const YoutubePlayerParams(showFullscreenButton: true),
        );
        _youtubeController = controller;
        _youtubeSubscription = controller.listen(_handleYoutubePlayerValue);
        setState(() {
          _isInitialized = true;
          _showControls = true;
        });
        _youtubeProgressTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _saveYoutubeProgress(),
        );
        return;
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': '*/*',
        },
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted || loadId != _playerLoadId) {
        await controller.dispose();
        return;
      }

      controller.addListener(_handlePlayerListener);
      await controller.setPlaybackSpeed(_currentSpeed);
      await controller.play();

      if (!mounted || loadId != _playerLoadId) return;
      setState(() {
        _isInitialized = true;
        _showControls = true;
      });
      _startHideControlsTimer();
    } catch (e) {
      if (mounted && loadId == _playerLoadId) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handleYoutubePlayerValue(YoutubePlayerValue value) {
    if (!mounted || _youtubeController == null) return;
    if (value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = 'YouTube playback failed (${value.error}).';
      });
      return;
    }
    if (value.playerState == PlayerState.ended &&
        _autoPlayNext &&
        _autoAdvancedLectureId != _currentLecture.id) {
      _autoAdvancedLectureId = _currentLecture.id;
      unawaited(context.read<CourseProvider>().updateLectureProgress(
            widget.course.id,
            _currentLecture.id,
            1,
          ));
      _playNextLecture();
    }
  }

  Future<void> _saveYoutubeProgress() async {
    final controller = _youtubeController;
    if (controller == null || _youtubeProgressPollActive || !mounted) return;
    _youtubeProgressPollActive = true;
    try {
      final currentSeconds = await controller.currentTime;
      final durationSeconds = await controller.duration;
      if (!mounted || controller != _youtubeController) return;

      final position = Duration(seconds: currentSeconds.floor());
      final duration = Duration(seconds: durationSeconds.floor());
      _youtubePosition = position;
      if (duration.inSeconds <= 0) return;

      final progress = (position.inMilliseconds / duration.inMilliseconds)
          .clamp(0.0, 1.0)
          .toDouble();
      if (position.inSeconds >= _lastProgressSavedSecond + 5 ||
          (progress >= 0.9 && !_completionProgressSaved)) {
        _lastProgressSavedSecond = position.inSeconds;
        if (progress >= 0.9) _completionProgressSaved = true;
        await context.read<CourseProvider>().updateLectureProgress(
              widget.course.id,
              _currentLecture.id,
              progress,
            );
      }
    } catch (error) {
      if (mounted && controller == _youtubeController) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not read YouTube playback progress: $error';
        });
      }
    } finally {
      _youtubeProgressPollActive = false;
    }
  }

  void _handlePlayerListener() {
    if (!mounted || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    final playerValue = _controller!.value;
    if (playerValue.hasError) {
      if (!_hasError) {
        setState(() {
          _hasError = true;
          _errorMessage =
              playerValue.errorDescription ?? 'Video playback failed.';
        });
      }
      return;
    }

    final duration = _controller!.value.duration.inMilliseconds;
    final position = _controller!.value.position.inMilliseconds;

    if (duration > 0) {
      final progress = position / duration;
      final positionSecond = _controller!.value.position.inSeconds;
      if (positionSecond >= _lastProgressSavedSecond + 5 ||
          (progress >= 0.9 && !_completionProgressSaved)) {
        _lastProgressSavedSecond = positionSecond;
        if (progress >= 0.9) _completionProgressSaved = true;
        context.read<CourseProvider>().updateLectureProgress(
            widget.course.id, _currentLecture.id, progress);
      }

      // Auto play next lecture on complete
      if (_autoPlayNext &&
          position >= duration - 500 &&
          duration > 1000 &&
          _autoAdvancedLectureId != _currentLecture.id) {
        _autoAdvancedLectureId = _currentLecture.id;
        _playNextLecture();
      }
    }
  }

  void _switchLecture(Lecture lecture) {
    if (lecture.id == _currentLecture.id) return;
    setState(() {
      _currentLecture = lecture;
      _lastProgressSavedSecond = -1;
      _completionProgressSaved = false;
      _autoAdvancedLectureId = null;
    });
    _initializePlayer(lecture.videoUrl);
  }

  void _playNextLecture() {
    final activeCourse = context.read<CourseProvider>().allCourses.firstWhere(
          (c) => c.id == widget.course.id,
          orElse: () => widget.course,
        );
    final currentIndex =
        activeCourse.lectures.indexWhere((l) => l.id == _currentLecture.id);
    if (currentIndex != -1 && currentIndex < activeCourse.lectures.length - 1) {
      _switchLecture(activeCourse.lectures[currentIndex + 1]);
    }
  }

  void _playPreviousLecture() {
    final activeCourse = context.read<CourseProvider>().allCourses.firstWhere(
          (c) => c.id == widget.course.id,
          orElse: () => widget.course,
        );
    final currentIndex =
        activeCourse.lectures.indexWhere((l) => l.id == _currentLecture.id);
    if (currentIndex > 0) {
      _switchLecture(activeCourse.lectures[currentIndex - 1]);
    }
  }

  void _seekRelative(int seconds) {
    if (_controller != null && _controller!.value.isInitialized) {
      final currentPos = _controller!.value.position;
      final target = currentPos + Duration(seconds: seconds);
      final clamped = target < Duration.zero
          ? Duration.zero
          : (target > _controller!.value.duration
              ? _controller!.value.duration
              : target);
      _controller!.seekTo(clamped);
      _startHideControlsTimer();
      return;
    }
    if (_youtubeController != null) {
      _youtubeController!.currentTime.then((curr) {
        if (!mounted || _youtubeController == null) return;
        _youtubeController!.seekTo(seconds: (curr + seconds).clamp(0, 999999));
      });
      _startHideControlsTimer();
    }
  }

  void _seekToSeconds(int seconds) {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.seekTo(Duration(seconds: seconds));
      _startHideControlsTimer();
      return;
    }
    if (_youtubeController != null) {
      _youtubeController!.seekTo(seconds: seconds.toDouble());
      _startHideControlsTimer();
    }
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _currentSpeed = speed;
    });
    _controller?.setPlaybackSpeed(speed);
    _youtubeController?.setPlaybackRate(speed);
    _startHideControlsTimer();
  }

  void _toggleVideoFit() {
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.cover;
      } else if (_videoFit == BoxFit.cover) {
        _videoFit = BoxFit.fill;
      } else {
        _videoFit = BoxFit.contain;
      }
    });
  }

  Future<void> _toggleFullscreen() async {
    if (_isChangingFullscreen) return;
    final enteringFullscreen = !_isFullscreen;
    _isChangingFullscreen = true;
    try {
      if (enteringFullscreen) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        await _restorePortraitSystemUi();
      }
      if (!mounted) return;
      setState(() {
        _isFullscreen = enteringFullscreen;
        _showControls = true;
      });
      _startHideControlsTimer();
    } on PlatformException catch (error) {
      if (enteringFullscreen) await _restorePortraitSystemUi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unable to change player orientation: ${error.message ?? error.code}'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      _isChangingFullscreen = false;
    }
  }

  Future<void> _restorePortraitSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp],
    );
  }

  void _showSpeedPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: speeds.map((s) {
                    final isSelected = s == _currentSpeed;
                    return ChoiceChip(
                      label: Text('${s}x'),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      onSelected: (_) {
                        _changePlaybackSpeed(s);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSleepTimerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = [
          {'label': 'Off', 'minutes': 0},
          {'label': '15 Minutes', 'minutes': 15},
          {'label': '30 Minutes', 'minutes': 30},
          {'label': '45 Minutes', 'minutes': 45},
          {'label': '60 Minutes', 'minutes': 60},
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sleep Timer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final label = opt['label'] as String;
                  final min = opt['minutes'] as int;
                  final isSelected = _sleepTimerLabel == label;
                  return ListTile(
                    leading: Icon(Icons.timer_outlined,
                        color: isSelected
                            ? AppTheme.primaryGlow
                            : AppTheme.textSecondary),
                    title: Text(label,
                        style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary)),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.primaryGlow)
                        : null,
                    onTap: () {
                      _sleepTimer?.cancel();
                      if (min > 0) {
                        _sleepTimer = Timer(Duration(minutes: min), () {
                          _controller?.pause();
                          _youtubeController?.pauseVideo();
                          if (mounted) setState(() {});
                        });
                        setState(() => _sleepTimerLabel = label);
                      } else {
                        setState(() => _sleepTimerLabel = 'Off');
                      }
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _playerLoadId++;
    _hideControlsTimer?.cancel();
    _sleepTimer?.cancel();
    _youtubeProgressTimer?.cancel();
    _controller?.removeListener(_handlePlayerListener);
    _controller?.dispose();
    unawaited(_youtubeSubscription?.cancel());
    unawaited(_youtubeController?.close());
    unawaited(_restorePortraitSystemUi());
    _tabController.dispose();
    _noteInputController.dispose();
    _eqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCourse = context.watch<CourseProvider>().allCourses.firstWhere(
          (c) => c.id == widget.course.id,
          orElse: () => widget.course,
        );

    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullscreen) {
          _toggleFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          top: !_isFullscreen,
          bottom: !_isFullscreen,
          child: Column(
            children: [
              // Video Player Viewport with Gestures & HUD
              if (_isFullscreen)
                Expanded(child: _buildVideoPlayerArea(fullscreen: true))
              else
                _buildVideoPlayerArea(),

              if (!_isFullscreen) ...[
                // Sleek Horizontal Tab Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.cardBorder.withAlpha(120),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppTheme.primaryGlow,
                    indicatorWeight: 3.0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Text('Videos (${activeCourse.lectures.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.description_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('Docs (${activeCourse.documents.length})'),
                          ],
                        ),
                      ),
                      const Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note, size: 19),
                            SizedBox(width: 8),
                            Text('Notes'),
                          ],
                        ),
                      ),
                      const Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Overview'),
                          ],
                        ),
                      ),
                      const Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.tune_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Tech Specs'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlaylistTab(activeCourse),
                      _buildDocumentsTab(activeCourse),
                      _buildNotesTab(),
                      _buildOverviewTab(activeCourse),
                      _buildDetailsTab(activeCourse),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayerArea({bool fullscreen = false}) {
    final player = Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Underlying Video Viewport
          if (_isInitialized && _youtubeController != null && !_hasError)
            YoutubePlayer(
              controller: _youtubeController!,
              aspectRatio: 16 / 9,
              backgroundColor: Colors.black,
              keepAlive: true,
            )
          else if (_isInitialized && _controller != null && !_hasError)
            FittedBox(
              fit: _videoFit,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (_hasError)
            _buildErrorView()
          else
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGlow),
            ),

          // Gesture Detector Layer (Double tap left/right, single tap toggle)
          if (_isInitialized && _controller != null && !_hasError)
            Positioned.fill(
              child: Row(
                children: [
                  // Left half (seek -10s)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleControls,
                      onDoubleTap: () {
                        if (_isLocked) return;
                        _seekRelative(-10);
                        setState(() => _showSeekLeftIndicator = true);
                        Timer(const Duration(milliseconds: 650), () {
                          if (mounted) {
                            setState(() => _showSeekLeftIndicator = false);
                          }
                        });
                      },
                    ),
                  ),
                  // Right half (seek +10s)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleControls,
                      onDoubleTap: () {
                        if (_isLocked) return;
                        _seekRelative(10);
                        setState(() => _showSeekRightIndicator = true);
                        Timer(const Duration(milliseconds: 650), () {
                          if (mounted) {
                            setState(() => _showSeekRightIndicator = false);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Animated Double-Tap Feedback Overlays
          if (_showSeekLeftIndicator)
            Positioned(
              left: 36,
              child: _buildSeekFeedbackIndicator(Icons.replay_10, '-10s'),
            ),
          if (_showSeekRightIndicator)
            Positioned(
              right: 36,
              child: _buildSeekFeedbackIndicator(Icons.forward_10, '+10s'),
            ),

          // Video Controls Overlay (Auto-hides)
          if (_isInitialized && _controller != null && !_hasError)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (context, value, child) {
                return Stack(
                  children: [
                    if (value.isBuffering)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGlow,
                        ),
                      ),
                    _buildControlsOverlay(),
                  ],
                );
              },
            ),
        ],
      ),
    );
    if (fullscreen) return player;
    return LayoutBuilder(
      builder: (context, constraints) {
        final naturalHeight = constraints.maxWidth * 9 / 16;
        final maxHeight = MediaQuery.sizeOf(context).height * 0.55;
        return SizedBox(
          width: double.infinity,
          height: math.min(naturalHeight, maxHeight),
          child: player,
        );
      },
    );
  }

  Widget _buildSeekFeedbackIndicator(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(190),
        borderRadius: BorderRadius.circular(30),
        border:
            Border.all(color: AppTheme.primaryGlow.withAlpha(140), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(80),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final pos = _controller?.value.position ?? _youtubePosition;
    final dur = _controller?.value.duration ?? Duration.zero;
    final isPlaying = _controller?.value.isPlaying ?? false;

    if (_isLocked) {
      // Show only unlock button when locked
      return SafeArea(
        child: Container(
          color: Colors.black38,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: () {
              setState(() => _isLocked = false);
              _startHideControlsTimer();
            },
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withAlpha(50), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Unlock Controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: IgnorePointer(
        ignoring: !_showControls,
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withAlpha(200),
                  Colors.transparent,
                  Colors.black.withAlpha(220),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TOP BAR: Back, Lecture Info, Actions
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: _isFullscreen
                            ? 'Exit fullscreen and return'
                            : 'Back',
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _isFullscreen
                            ? _toggleFullscreen
                            : () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentLecture.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.course.title,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Aspect Ratio: ${_videoFit.name}',
                        icon: const Icon(Icons.aspect_ratio,
                            color: Colors.white, size: 20),
                        onPressed: _toggleVideoFit,
                      ),
                      IconButton(
                        tooltip: 'Lock Controls',
                        icon: const Icon(Icons.lock_open,
                            color: Colors.white, size: 20),
                        onPressed: () => setState(() => _isLocked = true),
                      ),
                      IconButton(
                        tooltip: 'Sleep Timer: $_sleepTimerLabel',
                        icon: Icon(
                          Icons.timer_outlined,
                          color: _sleepTimerLabel != 'Off'
                              ? AppTheme.accent
                              : Colors.white,
                          size: 20,
                        ),
                        onPressed: _showSleepTimerPicker,
                      ),
                    ],
                  ),
                ),

                // CENTER TRANSPORT CONTROLS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.skip_previous,
                          color: Colors.white70),
                      onPressed: _playPreviousLecture,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      iconSize: 34,
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () => _seekRelative(-10),
                    ),
                    const SizedBox(width: 14),
                    // Glowing Play/Pause Button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(120),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        iconSize: 56,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (_controller != null) {
                            if (_controller!.value.isPlaying) {
                              _controller!.pause();
                            } else {
                              _controller!.play();
                            }
                          }
                          setState(() {});
                          _startHideControlsTimer();
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      iconSize: 34,
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () => _seekRelative(10),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.skip_next, color: Colors.white70),
                      onPressed: _playNextLecture,
                    ),
                  ],
                ),

                // BOTTOM BAR: Scrubber, Timestamps & Speed
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        colors: const VideoProgressColors(
                          playedColor: AppTheme.primaryGlow,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _showSpeedPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.surfaceElevated.withAlpha(220),
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: Text(
                                    '${_currentSpeed}x',
                                    style: const TextStyle(
                                      color: AppTheme.secondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: _isFullscreen
                                    ? 'Exit fullscreen'
                                    : 'Enter fullscreen',
                                icon: Icon(
                                  _isFullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleFullscreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 44),
          const SizedBox(height: 8),
          const Text(
            'Failed to stream video lecture',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Video Stream'),
            onPressed: () => _initializePlayer(_currentLecture.videoUrl),
          ),
          if (_isFullscreen)
            IconButton(
              tooltip: 'Exit fullscreen',
              onPressed: _toggleFullscreen,
              icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTab(Course course) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Auto-play next header toggle
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 6, right: 6, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${course.lectures.length} Lectures in Syllabus',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Auto-Play Next',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _autoPlayNext,
                    activeColor: AppTheme.primaryGlow,
                    onChanged: (value) => setState(() => _autoPlayNext = value),
                  ),
                ],
              ),
            ],
          ),
        ),

        ...course.lectures.map((lecture) {
          final isSelected = lecture.id == _currentLecture.id;
          final isCompleted =
              lecture.isCompleted || lecture.watchProgress >= 0.9;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.surfaceElevated : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGlow : AppTheme.cardBorder,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(40),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: isSelected
                    ? AppTheme.primary
                    : (isCompleted
                        ? AppTheme.success.withAlpha(40)
                        : AppTheme.surfaceElevated),
                foregroundColor:
                    isSelected ? Colors.white : AppTheme.textSecondary,
                child: isSelected
                    ? AnimatedBuilder(
                        animation: _eqController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildEqBar(0.4 + 0.6 * _eqController.value),
                              const SizedBox(width: 2),
                              _buildEqBar(0.8 - 0.5 * _eqController.value),
                              const SizedBox(width: 2),
                              _buildEqBar(0.3 + 0.7 * _eqController.value),
                            ],
                          );
                        },
                      )
                    : (isCompleted
                        ? const Icon(Icons.check,
                            size: 18, color: AppTheme.success)
                        : Text('${lecture.number}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold))),
              ),
              title: Text(
                lecture.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      lecture.duration,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 8),
                    if (lecture.watchProgress > 0)
                      Text(
                        isCompleted
                            ? '✓ Watched'
                            : '${(lecture.watchProgress * 100).toInt()}% watched',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted
                              ? AppTheme.success
                              : AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.graphic_eq, color: AppTheme.primaryGlow)
                  : const Icon(Icons.play_circle_outline,
                      color: AppTheme.textMuted, size: 20),
              onTap: () => _switchLecture(lecture),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEqBar(double heightFactor) {
    return Container(
      width: 2.5,
      height: 14 * heightFactor,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDocumentsTab(Course course) {
    final docs = course.documents;
    if (docs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 8),
            Text(
              'No companion documents attached.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final CourseDocument doc = docs[index];
        IconData icon;
        Color iconColor;
        Color bgColor;

        switch (doc.type) {
          case 'slides':
          case 'pdf':
            icon = Icons.picture_as_pdf;
            iconColor = const Color(0xFFF43F5E);
            bgColor = const Color(0xFFF43F5E).withAlpha(40);
            break;
          case 'code':
            icon = Icons.code_rounded;
            iconColor = AppTheme.primaryGlow;
            bgColor = AppTheme.primary.withAlpha(40);
            break;
          case 'cheatsheet':
            icon = Icons.bolt;
            iconColor = AppTheme.accent;
            bgColor = AppTheme.accent.withAlpha(40);
            break;
          default:
            icon = Icons.article_outlined;
            iconColor = AppTheme.secondary;
            bgColor = AppTheme.secondary.withAlpha(40);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doc.description,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.type.toUpperCase()} • ${doc.sizeFormatted}',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_for_offline_outlined,
                      color: AppTheme.secondary, size: 22),
                  tooltip: 'Save Offline',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Saved "${doc.title}" for offline study!'),
                        backgroundColor: AppTheme.surfaceElevated,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    return Consumer<NotesProvider>(
      builder: (context, notesProv, _) {
        final notes = notesProv.getNotesForLecture(_currentLecture.id);
        final currentPos = _controller?.value.position ?? _youtubePosition;

        return Column(
          children: [
            // Quick Note input bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                    bottom: BorderSide(color: AppTheme.cardBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Text(
                      _formatDuration(currentPos),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _noteInputController,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Bookmark thought at ${_formatDuration(currentPos)}...',
                        hintStyle: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onPressed: () {
                      final text = _noteInputController.text.trim();
                      if (text.isEmpty) return;

                      notesProv.addNote(
                        courseId: widget.course.id,
                        lectureId: _currentLecture.id,
                        lectureTitle: _currentLecture.title,
                        timestampSeconds: currentPos.inSeconds,
                        content: text,
                      );
                      _noteInputController.clear();
                      FocusScope.of(context).unfocus();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),

            // Notes list
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note,
                              size: 48,
                              color: AppTheme.textMuted.withAlpha(120)),
                          const SizedBox(height: 8),
                          const Text(
                            'No notes for this lecture yet.',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Type above to save timestamp-synced study bookmarks!',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: ListTile(
                            leading: ActionChip(
                              label: Text(note.formattedTimestamp),
                              labelStyle: const TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              backgroundColor: AppTheme.surfaceElevated,
                              side: const BorderSide(
                                  color: AppTheme.secondary, width: 0.8),
                              onPressed: () =>
                                  _seekToSeconds(note.timestampSeconds),
                            ),
                            title: Text(
                              note.content,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppTheme.textMuted),
                              onPressed: () => notesProv.deleteNote(note.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailsTab(Course course) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live Stream Engine Specs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.darkCardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorderGlow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cloud Stream Active',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  ),
                  const Text(
                    'Full HD 1080p',
                    style: TextStyle(
                        color: AppTheme.primaryGlow,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.cardBorder),
              const SizedBox(height: 12),
              _buildMetaRow(
                  'Delivery Network', 'Direct High-Speed Cloud CDN Stream'),
              _buildMetaRow(
                  'Resolution & Codec', '1080p Full HD (H.264 / AAC Audio)'),
              _buildMetaRow('Offline Caching', 'Device Local Buffer Enabled'),
              _buildMetaRow('Total Course Size', course.sizeFormatted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Open Educational Licensing Credits Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppTheme.surfaceElevated,
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppTheme.cardBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.verified_user_outlined,
              size: 18, color: AppTheme.secondary),
          label: const Text('View Content Sources & Licensing Credits'),
          onPressed: () => SourcesCreditsDialog.show(context),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(Course course) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Course title & badges
        Text(
          course.title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Chip(
              label: Text(course.level),
              backgroundColor: AppTheme.primary.withAlpha(40),
              side: const BorderSide(color: AppTheme.primary, width: 0.5),
              labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
            ),
            Chip(
              label: Text('★ ${course.rating}'),
              backgroundColor: AppTheme.accent.withAlpha(40),
              side: const BorderSide(color: AppTheme.accent, width: 0.5),
              labelStyle: const TextStyle(fontSize: 11, color: AppTheme.accent),
            ),
            Chip(
              label: Text(course.university),
              backgroundColor: AppTheme.surfaceElevated,
              side: const BorderSide(color: AppTheme.cardBorder),
              labelStyle:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          course.description,
          style: const TextStyle(
              fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 18),
        const Text(
          'Technologies & Skills Covered',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: course.techStacks.map((tech) {
            return Chip(
              label: Text('#$tech'),
              backgroundColor: AppTheme.surfaceElevated,
              side: const BorderSide(color: AppTheme.cardBorder),
              labelStyle:
                  const TextStyle(fontSize: 11, color: AppTheme.secondary),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
