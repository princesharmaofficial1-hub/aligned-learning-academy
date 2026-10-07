import 'dart:async';

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
import '../providers/settings_provider.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../theme/tech_palette.dart';
import '../widgets/app_components.dart';
import '../widgets/sources_credits_dialog.dart';

/// Lecture player: a 16:9 stage with a tokenised HUD, plus four peer views over
/// the same curriculum record — playlist, resources, notes and stream info.
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
  PlayerState? _youtubePlayerState;
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

  /// 0 = playlist, 1 = resources, 2 = notes, 3 = info.
  int _viewIndex = 0;

  // Player settings & behaviours
  double _currentSpeed = 1.0;
  bool _showControls = true;
  bool _isLocked = false;
  bool _autoPlayNext = true;
  bool _autoPlaySynced = false;
  BoxFit _videoFit = BoxFit.contain;
  Timer? _hideControlsTimer;
  Timer? _sleepTimer;
  String _sleepTimerLabel = 'Off';

  // Double-tap feedback
  bool _showSeekLeftIndicator = false;
  bool _showSeekRightIndicator = false;

  final TextEditingController _noteInputController = TextEditingController();

  /// Drives the now-playing equaliser bars in the playlist.
  late AnimationController _eqController;

  bool get _isPlaying =>
      _controller?.value.isPlaying ??
      _youtubePlayerState == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _currentLecture = widget.initialLecture;

    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initializePlayer(_currentLecture.videoUrl);
    _startHideControlsTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoPlaySynced) return;
    _autoPlaySynced = true;
    _autoPlayNext = context.read<SettingsProvider>().autoPlayNext;
  }

  // ===========================================================================
  // Chrome visibility
  // ===========================================================================

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (!_showControls || _isLocked) return;
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  // ===========================================================================
  // Player lifecycle
  // ===========================================================================

  Future<void> _initializePlayer(String url) async {
    final loadId = ++_playerLoadId;
    final previousController = _controller;
    final previousYoutubeController = _youtubeController;
    _controller = null;
    _youtubeController = null;
    _youtubePlayerState = null;
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
    if (value.playerState != _youtubePlayerState) {
      _youtubePlayerState = value.playerState;
      if (mounted) setState(() {});
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
      if (mounted) setState(() {});
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

  // ===========================================================================
  // Navigation between lectures
  // ===========================================================================

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

  Course get _activeCourse =>
      context.read<CourseProvider>().allCourses.firstWhere(
            (c) => c.id == widget.course.id,
            orElse: () => widget.course,
          );

  void _playNextLecture() {
    final course = _activeCourse;
    final currentIndex =
        course.lectures.indexWhere((l) => l.id == _currentLecture.id);
    if (currentIndex != -1 && currentIndex < course.lectures.length - 1) {
      _switchLecture(course.lectures[currentIndex + 1]);
    }
  }

  void _playPreviousLecture() {
    final course = _activeCourse;
    final currentIndex =
        course.lectures.indexWhere((l) => l.id == _currentLecture.id);
    if (currentIndex > 0) {
      _switchLecture(course.lectures[currentIndex - 1]);
    }
  }

  // ===========================================================================
  // Transport
  // ===========================================================================

  void _seekRelative(int seconds) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      final target = controller.value.position + Duration(seconds: seconds);
      final duration = controller.value.duration;
      controller.seekTo(target < Duration.zero
          ? Duration.zero
          : (target > duration ? duration : target));
      _startHideControlsTimer();
      return;
    }
    final youtube = _youtubeController;
    if (youtube != null) {
      youtube.currentTime.then((current) {
        if (!mounted || _youtubeController == null) return;
        youtube.seekTo(seconds: (current + seconds).clamp(0, 999999));
      });
      _startHideControlsTimer();
    }
  }

  void _seekToSeconds(int seconds) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      controller.seekTo(Duration(seconds: seconds));
      _startHideControlsTimer();
      return;
    }
    _youtubeController?.seekTo(seconds: seconds.toDouble());
    _startHideControlsTimer();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      setState(() {});
    } else {
      final youtube = _youtubeController;
      if (youtube != null) {
        if (_youtubePlayerState == PlayerState.playing) {
          youtube.pauseVideo();
        } else {
          youtube.playVideo();
        }
      }
    }
    _startHideControlsTimer();
  }

  void _changePlaybackSpeed(double speed) {
    setState(() => _currentSpeed = speed);
    _controller?.setPlaybackSpeed(speed);
    _youtubeController?.setPlaybackRate(speed);
    _startHideControlsTimer();
  }

  void _toggleVideoFit() {
    setState(() {
      _videoFit = switch (_videoFit) {
        BoxFit.contain => BoxFit.cover,
        BoxFit.cover => BoxFit.fill,
        _ => BoxFit.contain,
      };
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
        showAppSnack(
          context,
          'Unable to change player orientation: ${error.message ?? error.code}',
          icon: Icons.screen_rotation_alt_rounded,
          isError: true,
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

  // ===========================================================================
  // Sheets
  // ===========================================================================

  void _showSpeedPicker() {
    const speeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            0,
            AppSpace.gutter,
            AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Playback speed', style: context.text.titleLarge),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: <Widget>[
                  for (final speed in speeds)
                    AppPill(
                      label: '${speed}x',
                      icon: speed == _currentSpeed
                          ? Icons.check_rounded
                          : Icons.speed_rounded,
                      color: speed == _currentSpeed
                          ? context.colors.primary
                          : context.tokens.textMuted,
                      selected: speed == _currentSpeed,
                      onTap: () {
                        _changePlaybackSpeed(speed);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepTimerPicker() {
    const options = <(String, int)>[
      ('Off', 0),
      ('15 minutes', 15),
      ('30 minutes', 30),
      ('45 minutes', 45),
      ('60 minutes', 60),
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            0,
            AppSpace.gutter,
            AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Sleep timer', style: context.text.titleLarge),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Playback pauses automatically so you can rest.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: AppSpace.lg),
              for (final (label, minutes) in options)
                _PickerRow(
                  icon: minutes == 0
                      ? Icons.notifications_off_outlined
                      : Icons.bedtime_rounded,
                  label: label,
                  selected: _sleepTimerLabel == label,
                  onTap: () {
                    _sleepTimer?.cancel();
                    if (minutes > 0) {
                      _sleepTimer = Timer(Duration(minutes: minutes), () {
                        _controller?.pause();
                        _youtubeController?.pauseVideo();
                        if (mounted) {
                          setState(() => _sleepTimerLabel = 'Ended');
                        }
                      });
                    }
                    setState(() => _sleepTimerLabel = label);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Duration get _position => _controller?.value.position ?? _youtubePosition;

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
    _noteInputController.dispose();
    _eqController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final activeCourse = context.watch<CourseProvider>().allCourses.firstWhere(
          (c) => c.id == widget.course.id,
          orElse: () => widget.course,
        );

    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullscreen) _toggleFullscreen();
      },
      child: Scaffold(
        backgroundColor: t.canvas,
        body: SafeArea(
          top: !_isFullscreen,
          bottom: !_isFullscreen,
          child: Column(
            children: <Widget>[
              if (_isFullscreen)
                Expanded(child: _buildStage())
              else
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildStage(),
                ),
              if (!_isFullscreen) ...<Widget>[
                _NowPlayingBar(
                  lecture: _currentLecture,
                  course: widget.course,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.md,
                    AppSpace.gutter,
                    AppSpace.md,
                  ),
                  child: AppSegmentControl(
                    labels: <String>[
                      'Playlist',
                      'Docs${activeCourse.documents.isEmpty ? '' : ' ${activeCourse.documents.length}'}',
                      'Notes',
                      'Info',
                    ],
                    icons: const <IconData>[
                      Icons.playlist_play_rounded,
                      Icons.description_outlined,
                      Icons.edit_note_rounded,
                      Icons.info_outline_rounded,
                    ],
                    selectedIndex: _viewIndex,
                    onChanged: (value) => setState(() => _viewIndex = value),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _viewIndex,
                    children: <Widget>[
                      _buildPlaylistTab(activeCourse),
                      _buildResourcesTab(activeCourse),
                      _buildNotesTab(),
                      _buildInfoTab(activeCourse),
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

  // ===========================================================================
  // Stage
  // ===========================================================================

  Widget _buildStage() {
    final hasVideo = _isInitialized && !_hasError;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (hasVideo && _youtubeController != null)
            YoutubePlayer(
              controller: _youtubeController!,
              aspectRatio: 16 / 9,
              backgroundColor: Colors.black,
              keepAlive: true,
            )
          else if (hasVideo && _controller != null)
            Center(
              child: FittedBox(
                fit: _videoFit,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else if (_hasError)
            _buildErrorView()
          else
            Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: context.tokens.brandGlow,
                ),
              ),
            ),
          if (hasVideo) ...<Widget>[
            // Single tap toggles the HUD, double tap seeks ±10s.
            Positioned.fill(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _StageGestureArea(
                      onTap: _toggleControls,
                      onDoubleTap: () {
                        if (_isLocked) return;
                        _seekRelative(-10);
                        _flashSeekFeedback(left: true);
                      },
                    ),
                  ),
                  Expanded(
                    child: _StageGestureArea(
                      onTap: _toggleControls,
                      onDoubleTap: () {
                        if (_isLocked) return;
                        _seekRelative(10);
                        _flashSeekFeedback(left: false);
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (_showSeekLeftIndicator)
              const Center(child: _SeekFeedback(icon: Icons.replay_10_rounded)),
            if (_showSeekRightIndicator)
              const Center(
                  child: _SeekFeedback(icon: Icons.forward_10_rounded)),

            if (_controller != null)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller!,
                builder: (context, value, _) => Stack(
                  children: <Widget>[
                    if (value.isBuffering)
                      Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: context.tokens.brandGlow,
                          ),
                        ),
                      ),
                    _buildHud(),
                  ],
                ),
              )
            else
              _buildHud(),
          ],
        ],
      ),
    );
  }

  void _flashSeekFeedback({required bool left}) {
    setState(() {
      if (left) {
        _showSeekLeftIndicator = true;
      } else {
        _showSeekRightIndicator = true;
      }
    });
    Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _showSeekLeftIndicator = false;
        _showSeekRightIndicator = false;
      });
    });
  }

  Widget _buildErrorView() {
    final t = context.tokens;

    return ColoredBox(
      color: t.canvasSunken,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.danger.withValues(alpha: AppAlpha.soft),
                    border: Border.all(
                      color: t.danger.withValues(alpha: AppAlpha.medium),
                    ),
                  ),
                  child: Icon(Icons.error_outline_rounded,
                      size: 30, color: t.danger),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  'Stream unavailable',
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: 'Retry stream',
                  icon: Icons.refresh_rounded,
                  expand: false,
                  onPressed: () => _initializePlayer(_currentLecture.videoUrl),
                ),
                if (_isFullscreen) ...<Widget>[
                  const SizedBox(height: AppSpace.md),
                  TextButton.icon(
                    onPressed: _toggleFullscreen,
                    icon: const Icon(Icons.fullscreen_exit_rounded,
                        size: AppIcon.sm),
                    label: const Text('Exit fullscreen'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HUD
  // ===========================================================================

  Widget _buildHud() {
    if (_isLocked) return _buildLockHud();

    return IgnorePointer(
      ignoring: !_showControls,
      child: AnimatedOpacity(
        opacity: _showControls ? 1 : 0,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.65),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.78),
              ],
              stops: const <double>[0, 0.45, 1],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: Column(
                children: <Widget>[
                  _hudTopBar(),
                  const Spacer(),
                  _hudTransport(),
                  const SizedBox(height: AppSpace.sm),
                  _hudScrubber(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockHud() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: _HudPill(
              icon: Icons.lock_rounded,
              label: 'Unlock controls',
              onTap: () {
                setState(() => _isLocked = false);
                _startHideControlsTimer();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _hudTopBar() {
    return Row(
      children: <Widget>[
        _HudIconButton(
          icon: _isFullscreen
              ? Icons.arrow_back_rounded
              : Icons.arrow_back_ios_new_rounded,
          tooltip: _isFullscreen ? 'Exit fullscreen' : 'Back',
          onTap:
              _isFullscreen ? _toggleFullscreen : () => Navigator.pop(context),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _currentLecture.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium!.copyWith(color: Colors.white),
              ),
              Text(
                widget.course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall!.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        _HudIconButton(
          icon: Icons.aspect_ratio_rounded,
          tooltip: 'Aspect ratio: ${_videoFit.name}',
          onTap: _toggleVideoFit,
        ),
        _HudIconButton(
          icon: Icons.lock_open_rounded,
          tooltip: 'Lock controls',
          onTap: () => setState(() => _isLocked = true),
        ),
        _HudIconButton(
          icon: Icons.bedtime_rounded,
          tooltip: 'Sleep timer: $_sleepTimerLabel',
          color: _sleepTimerLabel != 'Off' ? context.tokens.accent : null,
          onTap: _showSleepTimerPicker,
        ),
      ],
    );
  }

  Widget _hudTransport() {
    final t = context.tokens;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _HudIconButton(
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous lecture',
          size: 24,
          onTap: _playPreviousLecture,
        ),
        const SizedBox(width: AppSpace.sm),
        _HudIconButton(
          icon: Icons.replay_10_rounded,
          tooltip: 'Back 10 seconds',
          size: 28,
          onTap: () => _seekRelative(-10),
        ),
        const SizedBox(width: AppSpace.md),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: t.green.withValues(alpha: AppAlpha.glow),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: _HudIconButton(
            icon:
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            tooltip: _isPlaying ? 'Pause' : 'Play',
            size: 56,
            onTap: _togglePlayPause,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        _HudIconButton(
          icon: Icons.forward_10_rounded,
          tooltip: 'Forward 10 seconds',
          size: 28,
          onTap: () => _seekRelative(10),
        ),
        const SizedBox(width: AppSpace.sm),
        _HudIconButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next lecture',
          size: 24,
          onTap: _playNextLecture,
        ),
      ],
    );
  }

  Widget _hudScrubber() {
    final t = context.tokens;
    final duration = _controller?.value.duration ?? Duration.zero;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_controller != null)
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            colors: VideoProgressColors(
              playedColor: t.green,
              bufferedColor: Colors.white.withValues(alpha: 0.35),
              backgroundColor: Colors.white.withValues(alpha: 0.16),
            ),
          )
        else
          AppProgressBar(
            value: duration.inMilliseconds == 0
                ? 0
                : _position.inMilliseconds / duration.inMilliseconds,
            color: t.green,
            height: 4,
            background: Colors.white.withValues(alpha: 0.16),
          ),
        const SizedBox(height: 2),
        Row(
          children: <Widget>[
            Text(
              '${_formatDuration(_position)} / ${_formatDuration(duration)}',
              style: context.text.monoSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _HudPill(
              label: '${_currentSpeed}x',
              onTap: _showSpeedPicker,
            ),
            const SizedBox(width: AppSpace.sm),
            _HudIconButton(
              icon: _isFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              tooltip: _isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
              onTap: _toggleFullscreen,
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Playlist
  // ===========================================================================

  Widget _buildPlaylistTab(Course course) {
    final t = context.tokens;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xs,
        AppSpace.gutter,
        AppSpace.x4l,
      ),
      itemCount: course.lectures.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: AppSurface.inset(
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.bolt_rounded, size: AppIcon.sm, color: t.green),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      '${course.lectures.length} lectures in syllabus',
                      style: context.text.labelMedium,
                    ),
                  ),
                  Text('Auto-play next', style: context.text.labelSmall),
                  Switch(
                    value: _autoPlayNext,
                    onChanged: (value) {
                      setState(() => _autoPlayNext = value);
                      context.read<SettingsProvider>().setAutoPlayNext(value);
                    },
                  ),
                ],
              ),
            ),
          );
        }

        final lecture = course.lectures[index - 1];
        return _PlaylistRow(
          lecture: lecture,
          selected: lecture.id == _currentLecture.id,
          eqAnimation: _eqController,
          onTap: () => _switchLecture(lecture),
        );
      },
    );
  }

  // ===========================================================================
  // Resources
  // ===========================================================================

  Widget _buildResourcesTab(Course course) {
    final docs = course.documents;

    if (docs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const <Widget>[
          AppEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No companion documents',
            message:
                'This curriculum ships video lectures only. Slides and labs '
                'appear here when the repository publishes them.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xs,
        AppSpace.gutter,
        AppSpace.x4l,
      ),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, index) {
        final CourseDocument doc = docs[index];
        return _ResourceRow(
          doc: doc,
          onSave: () => showAppSnack(
            context,
            '“${doc.title}” cached for offline study',
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Notes
  // ===========================================================================

  Widget _buildNotesTab() {
    return Consumer<NotesProvider>(
      builder: (context, notes, _) {
        final t = context.tokens;
        final lectureNotes = notes.getNotesForLecture(_currentLecture.id);
        final position = _position;

        return Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.sm,
                AppSpace.gutter,
                AppSpace.md,
              ),
              decoration: BoxDecoration(
                color: t.canvas,
                border: Border(bottom: BorderSide(color: t.hairline)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  AppPill(
                    label: _formatDuration(position),
                    icon: Icons.schedule_rounded,
                    color: t.green,
                    dense: true,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: TextField(
                      controller: _noteInputController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveNote(notes, position),
                      style: context.text.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Bookmark a thought at '
                            '${_formatDuration(position)}…',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.md,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  IconButton.filled(
                    onPressed: () => _saveNote(notes, position),
                    tooltip: 'Save note',
                    iconSize: AppIcon.sm,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: lectureNotes.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: const <Widget>[
                        AppEmptyState(
                          compact: true,
                          icon: Icons.edit_note_rounded,
                          title: 'No notes for this lecture',
                          message:
                              'Capture timestamp-synced study bookmarks above — '
                              'they stay attached to this lecture forever.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.gutter,
                        AppSpace.md,
                        AppSpace.gutter,
                        AppSpace.x4l,
                      ),
                      itemCount: lectureNotes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpace.sm),
                      itemBuilder: (context, index) {
                        final note = lectureNotes[index];
                        return AppSurface.inset(
                          radius: AppRadius.md,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.md,
                            AppSpace.md,
                            AppSpace.xs,
                            AppSpace.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              AppPill(
                                label: note.formattedTimestamp,
                                icon: Icons.play_arrow_rounded,
                                color: t.green,
                                dense: true,
                                selected: true,
                                onTap: () =>
                                    _seekToSeconds(note.timestampSeconds),
                              ),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Text(
                                  note.content,
                                  style: context.text.bodyMedium,
                                ),
                              ),
                              IconButton(
                                onPressed: () => notes.deleteNote(note.id),
                                tooltip: 'Delete note',
                                iconSize: AppIcon.sm,
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: t.textMuted,
                                ),
                              ),
                            ],
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

  void _saveNote(NotesProvider notes, Duration position) {
    final text = _noteInputController.text.trim();
    if (text.isEmpty) return;

    notes.addNote(
      courseId: widget.course.id,
      lectureId: _currentLecture.id,
      lectureTitle: _currentLecture.title,
      timestampSeconds: position.inSeconds,
      content: text,
    );
    _noteInputController.clear();
    FocusScope.of(context).unfocus();
    showAppSnack(context, 'Note saved at ${_formatDuration(position)}');
  }

  // ===========================================================================
  // Info
  // ===========================================================================

  Widget _buildInfoTab(Course course) {
    final t = context.tokens;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xs,
        AppSpace.gutter,
        AppSpace.x4l,
      ),
      children: <Widget>[
        // ---- Stream health ---------------------------------------------
        AppSurface(
          radius: AppRadius.lg,
          glow: t.success,
          border: BorderSide(color: t.success.withValues(alpha: 0.28)),
          gradient: LinearGradient(
            colors: <Color>[
              Color.alphaBlend(
                t.success.withValues(alpha: AppAlpha.wash),
                t.surface,
              ),
              t.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.success,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: t.success.withValues(alpha: AppAlpha.glow),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      'Cloud stream active',
                      style:
                          context.text.titleMedium!.copyWith(color: t.success),
                    ),
                  ),
                  AppPill(
                    label: 'FULL HD 1080p',
                    icon: Icons.hd_rounded,
                    color: t.brandGlow,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Divider(height: 1, color: t.hairline),
              const SizedBox(height: AppSpace.md),
              _SpecRow(
                label: 'Delivery network',
                value: 'Direct high-speed cloud CDN',
              ),
              _SpecRow(
                label: 'Resolution & codec',
                value: '1080p Full HD · H.264 / AAC',
              ),
              _SpecRow(
                label: 'Offline caching',
                value: 'Device local buffer enabled',
              ),
              _SpecRow(
                label: 'Curriculum size',
                value: course.sizeFormatted,
                showDivider: false,
              ),
            ],
          ),
        ),

        // ---- Curriculum identity ---------------------------------------
        const SectionHeader(
          title: 'Curriculum',
          padding: EdgeInsets.fromLTRB(0, AppSpace.section, 0, AppSpace.md),
        ),
        Text(course.title, style: context.text.titleLarge),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: <Widget>[
            AppPill(
              label: course.level,
              icon: Icons.signal_cellular_alt_rounded,
              color: context.levelColor(course.level),
              dense: true,
            ),
            AppPill(
              label: '★ ${course.rating}',
              icon: Icons.star_rounded,
              color: t.accent,
              dense: true,
            ),
            AppPill(
              label: course.university,
              icon: Icons.school_rounded,
              color: t.textMuted,
              dense: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Text(course.description, style: context.text.bodyMedium),

        const SectionHeader(
          title: 'Technologies & Skills',
          padding: EdgeInsets.fromLTRB(0, AppSpace.section, 0, AppSpace.md),
        ),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: <Widget>[
            for (final tech in course.techStacks)
              AppPill(
                label: tech,
                icon: TechPalette.iconFor(tech),
                color: context.techColor(tech),
                dense: true,
              ),
          ],
        ),

        const SizedBox(height: AppSpace.xl),
        AppButton(
          label: 'Content sources & licensing',
          icon: Icons.verified_user_rounded,
          variant: AppButtonVariant.outlined,
          onPressed: () => SourcesCreditsDialog.show(context),
        ),
      ],
    );
  }
}

// =============================================================================
// Stage pieces
// =============================================================================

class _StageGestureArea extends StatelessWidget {
  const _StageGestureArea({required this.onTap, required this.onDoubleTap});

  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Player surface. Double tap to seek ten seconds.',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
      ),
    );
  }
}

class _SeekFeedback extends StatelessWidget {
  const _SeekFeedback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.68),
          borderRadius: AppRadius.allPill,
          border: Border.all(
            color: context.tokens.green.withValues(alpha: 0.55),
          ),
        ),
        child: Icon(icon, size: AppIcon.xl, color: Colors.white),
      ),
    );
  }
}

/// Circular HUD control. Sits on video, so it keeps its own scrim surface.
class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = AppIcon.md,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: AppSpace.touchTarget,
            height: AppSpace.touchTarget,
            child: Icon(icon, size: size, color: color ?? Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.label, this.icon, this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: AppRadius.allPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppIcon.sm, color: Colors.white),
                const SizedBox(width: AppSpace.xs),
              ],
              Text(
                label,
                style: context.text.labelSmall!.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Now playing
// =============================================================================

class _NowPlayingBar extends StatelessWidget {
  const _NowPlayingBar({required this.lecture, required this.course});

  final Lecture lecture;
  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final done = lecture.isCompleted || lecture.watchProgress >= 0.9;
    final progress = lecture.watchProgress;
    final active = progress > 0 && !done;

    final statusColor = done ? t.success : (active ? t.green : t.textMuted);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: t.canvas,
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: Row(
        children: <Widget>[
          AppIconTile(
            icon: done
                ? Icons.check_circle_rounded
                : Icons.play_circle_fill_rounded,
            color: statusColor,
            size: 40,
            selected: true,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  lecture.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Lecture ${lecture.number} · ${course.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          if (progress > 0)
            AppPill(
              label: done ? 'Done' : '${(progress * 100).round()}%',
              icon: done ? Icons.verified_rounded : Icons.timelapse_rounded,
              color: statusColor,
              dense: true,
              selected: true,
            )
          else
            AppPill(
              label: lecture.duration,
              icon: Icons.schedule_rounded,
              color: t.textMuted,
              dense: true,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Playlist row
// =============================================================================

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.lecture,
    required this.selected,
    required this.eqAnimation,
    required this.onTap,
  });

  final Lecture lecture;
  final bool selected;
  final Animation<double> eqAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final done = lecture.isCompleted || lecture.watchProgress >= 0.9;
    final active = lecture.watchProgress > 0 && !done;

    final accent =
        selected ? context.colors.primary : (done ? t.success : null);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Lecture ${lecture.number}: ${lecture.title}',
      child: AppSurface(
        radius: AppRadius.md,
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        selected: selected,
        glow: active && !selected ? t.green : null,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.md,
          AppSpace.md,
          AppSpace.md,
        ),
        child: Row(
          children: <Widget>[
            _PlaylistBadge(
              number: lecture.number,
              done: done,
              selected: selected,
              animation: eqAnimation,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    lecture.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(lecture.duration, style: context.text.monoSmall),
                      if (lecture.isDownloaded)
                        AppPill(
                          label: 'Offline',
                          icon: Icons.download_done_rounded,
                          color: t.info,
                          dense: true,
                        ),
                      if (done)
                        AppPill(
                          label: 'Watched',
                          icon: Icons.check_circle_rounded,
                          color: t.success,
                          dense: true,
                          selected: true,
                        )
                      else if (active)
                        AppPill(
                          label: '${(lecture.watchProgress * 100).round()}%',
                          icon: Icons.timelapse_rounded,
                          color: t.green,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            if (selected)
              _Equaliser(color: accent ?? t.green, animation: eqAnimation)
            else
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.play_circle_outline_rounded,
                size: AppIcon.md,
                color: accent ?? t.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistBadge extends StatelessWidget {
  const _PlaylistBadge({
    required this.number,
    required this.done,
    required this.selected,
    required this.animation,
  });

  final int number;
  final bool done;
  final bool selected;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    final color = selected ? c.primary : (done ? t.success : t.textMuted);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlpha.soft),
        borderRadius: AppRadius.allSm,
        border: Border.all(color: color.withValues(alpha: AppAlpha.medium)),
      ),
      child: Center(
        child: selected
            ? _Equaliser(color: color, animation: animation)
            : done
                ? Icon(Icons.check_rounded, size: AppIcon.sm, color: color)
                : Text(
                    '$number',
                    style: context.text.labelMedium!.copyWith(color: color),
                  ),
      ),
    );
  }
}

class _Equaliser extends StatelessWidget {
  const _Equaliser({required this.color, required this.animation});

  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _bar(0.35 + 0.65 * animation.value),
          const SizedBox(width: 2),
          _bar(0.8 - 0.5 * animation.value),
          const SizedBox(width: 2),
          _bar(0.3 + 0.7 * animation.value),
        ],
      ),
    );
  }

  Widget _bar(double factor) {
    return Container(
      width: 3,
      height: 16 * factor.clamp(0.2, 1.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// =============================================================================
// Resource row
// =============================================================================

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.doc, required this.onSave});

  final CourseDocument doc;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = context.docColor(doc.type);

    return AppSurface(
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIconTile(
              icon: DocPalette.iconFor(doc.type), color: color, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  doc.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                if (doc.description.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    doc.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: <Widget>[
                    AppPill(
                      label: DocPalette.labelFor(doc.type),
                      color: color,
                      dense: true,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: Text(
                        doc.sizeFormatted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.monoSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSave,
            tooltip: 'Save resource offline',
            visualDensity: VisualDensity.compact,
            iconSize: AppIcon.md,
            icon: Icon(Icons.download_for_offline_outlined, color: t.green),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Info pieces
// =============================================================================

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Text(label, style: context.text.bodySmall)),
              const SizedBox(width: AppSpace.md),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: context.text.mono.copyWith(color: t.textPrimary),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: t.hairline),
      ],
    );
  }
}

/// Shared bottom-sheet row: icon, label, check when selected.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppSurface.inset(
      radius: AppRadius.md,
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      color: selected
          ? c.primary.withValues(alpha: AppAlpha.wash)
          : context.tokens.surface,
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: AppIcon.sm,
            color: selected ? c.primary : context.tokens.textMuted,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              label,
              style: context.text.bodyLarge!.copyWith(
                color: selected ? c.primary : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (selected)
            Icon(Icons.check_rounded, size: AppIcon.sm, color: c.primary),
        ],
      ),
    );
  }
}
