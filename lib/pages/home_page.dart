import 'package:visionmax/utils/color_extensions.dart';
import 'package:visionmax/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:vibration/vibration.dart';
import 'package:visionmax/core/object_detector_service.dart';
import 'dart:io' show Platform;

enum HomeTab {
  dashboard, // 0
  settings, // 1
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  HomeTab _selectedTab = HomeTab.dashboard;
  int get _selectedIndex => _selectedTab.index;

  late List<AnimationController> _animationControllers;
  late final List<Widget> _pages;
  final GlobalKey<HomeDashboardPageState> _dashboardKey =
      GlobalKey<HomeDashboardPageState>();
  final GlobalKey<SettingsPageState> _settingsKey =
      GlobalKey<SettingsPageState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeDashboardPage(key: _dashboardKey),
      SettingsPage(key: _settingsKey),
    ];
    // Only create controllers for the actual number of tabs
    _animationControllers = List.generate(HomeTab.values.length, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    });
    _animationControllers[_selectedIndex].forward();
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(HomeTab tab) {
    if (_selectedTab == tab) return;
    final prevIndex = _selectedIndex;
    setState(() {
      _selectedTab = tab;
    });
    _animationControllers[prevIndex].reverse();
    _animationControllers[_selectedIndex].forward();

    if (tab == HomeTab.dashboard) {
      _dashboardKey.currentState?.refreshTtsSettings();
    }
    if (tab == HomeTab.settings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _settingsKey.currentState?.reloadFromDisk();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        // Allow pop only when on dashboard (index 0), otherwise go back to dashboard
        canPop: _selectedTab == HomeTab.dashboard,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _onItemTapped(HomeTab.dashboard);
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: null,
          drawer: null,
          body: Row(
            children: [
              if (isWeb)
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      right: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacityValue(0.05)
                            : Colors.black.withOpacityValue(0.05),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Vision - Max',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        _SidebarItem(
                          icon: FontAwesomeIcons.house,
                          label: 'Home',
                          selected: _selectedIndex == 0,
                          onTap: () => _onItemTapped(HomeTab.dashboard),
                        ),
                        _SidebarItem(
                          icon: FontAwesomeIcons.gear,
                          label: 'Settings',
                          selected: _selectedIndex == HomeTab.settings.index,
                          onTap: () => _onItemTapped(HomeTab.settings),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    if (isDark)
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 1.0,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacityValue(0.15),
                                  ],
                                  stops: const [0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWeb
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacityValue(0.05)
                            : Colors.black.withOpacityValue(0.05),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(2, (index) {
                          final bool isSelected = _selectedIndex == index;

                          final List<Map<String, dynamic>> items = [
                            {'icon': FontAwesomeIcons.house, 'label': 'Home'},
                            {
                              'icon': FontAwesomeIcons.gear,
                              'label': 'Settings',
                            },
                          ];
                          final icon = items[index]['icon'] as IconData;
                          final label = items[index]['label'] as String;

                          return GestureDetector(
                            onTap: () => _onItemTapped(HomeTab.values[index]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                          .withOpacityValue(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                              .withOpacityValue(0.6),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                                .withOpacityValue(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => HomeDashboardPageState();
}

class HomeDashboardPageState extends State<HomeDashboardPage> {
  CameraController? _cameraController;
  late final ObjectDetectorService _detectorService;
  late final FlutterTts _flutterTts;

  bool _isCameraInitialized = false;
  bool _isTtsInitialized = false;
  bool _isScanning = false;
  bool _isProcessingFrame = false;

  String _detectionInstruction = 'Ready';
  ProximityLevel _currentProximity = ProximityLevel.safe;
  ScreenRegion _currentRegion = ScreenRegion.center;
  bool _currentIsCritical = false;

  String _lastSpokenInstruction = '';
  DateTime _lastSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));
  DateTime _lastNonCriticalSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));

  @override
  void initState() {
    super.initState();
    _detectorService = ObjectDetectorService();
    _initTts();
    _initializeCamera();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    try {
      double speechRate = 0.5;
      double volume = 1.0;
      double pitch = 1.0;
      try {
        final box = Hive.box('settings');
        speechRate =
            (box.get('speechRate', defaultValue: 0.5) as num).toDouble();
        volume =
            (box.get('volume', defaultValue: 1.0) as num).toDouble();
        pitch = (box.get('pitch', defaultValue: 1.0) as num).toDouble();
      } catch (e) {
        debugPrint('Hive read failed during TTS init (using defaults): $e');
      }

      if (Platform.isAndroid) {
        try {
          await _flutterTts.isLanguageInstalled("en-US");
        } catch (_) {}
      }

      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.setVolume(volume);
      await _flutterTts.setPitch(pitch);
      await _flutterTts.awaitSpeakCompletion(false);

      if (Platform.isAndroid) {
        try {
          await _flutterTts.speak("");
        } catch (_) {}
      }

      debugPrint('[VisionMax] TTS initialized. rate=$speechRate vol=$volume pitch=$pitch');

      if (mounted) {
        setState(() {
          _isTtsInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[VisionMax] Error initializing TTS: $e');
      if (mounted) {
        setState(() {
          _isTtsInitialized = true;
        });
      }
    }
  }

  Future<void> refreshTtsSettings() async {
    try {
      double speechRate = 0.5;
      double volume = 1.0;
      double pitch = 1.0;
      try {
        final box = Hive.box('settings');
        speechRate =
            (box.get('speechRate', defaultValue: 0.5) as num?)?.toDouble() ??
                0.5;
        volume =
            (box.get('volume', defaultValue: 1.0) as num?)?.toDouble() ?? 1.0;
        pitch = (box.get('pitch', defaultValue: 1.0) as num?)?.toDouble() ?? 1.0;
      } catch (e) {
        debugPrint('[VisionMax] Hive read failed in refreshTtsSettings: $e');
      }
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.setVolume(volume);
      await _flutterTts.setPitch(pitch);
      debugPrint('[VisionMax] TTS refreshed: r=$speechRate v=$volume p=$pitch');
    } catch (e) {
      debugPrint('[VisionMax] Error refreshing TTS settings: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _isScanning = false;
    if (_cameraController != null && _isCameraInitialized) {
      try {
        _cameraController!.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      }
    }
    try {
      _detectorService.dispose();
    } catch (e) {
      debugPrint('Error disposing detector service: $e');
    }
    try {
      _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
    super.dispose();
  }

  void _toggleScanning() {
    if (_isScanning) {
      _stopScanning();
    } else {
      _startScanning();
    }
  }

  void _showMessage(String text, {Duration duration = const Duration(seconds: 1), bool long = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: long ? const Duration(seconds: 3) : duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startScanning() async {
    debugPrint('[VisionMax] _startScanning called');
    if (!_isTtsInitialized) {
      debugPrint('[VisionMax] TTS not ready; waiting 500ms');
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (_cameraController == null || !_isCameraInitialized) {
      debugPrint('[VisionMax] Camera not ready; initializing');
      await _initializeCamera();
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('[VisionMax] Camera failed to initialize');
      _showMessage('Camera not ready. Check app permissions.', long: true);
      return;
    }

    setState(() {
      _isScanning = true;
      _detectionInstruction = 'Starting scanner...';
      _currentProximity = ProximityLevel.safe;
      _currentRegion = ScreenRegion.center;
      _currentIsCritical = false;
      _lastSpokenInstruction = '';
      _lastSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));
      _lastNonCriticalSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));
    });

    _showMessage('Scanning started');
    debugPrint('[VisionMax] Starting image stream');

    // Prime haptic + TTS with explicit startup announcement
    try {
      final hasV = await Vibration.hasVibrator();
      debugPrint('[VisionMax] hasVibrator=$hasV');
    } catch (e) {
      debugPrint('[VisionMax] vibrator probe error: $e');
    }

    _speakAlert(
      'Scanning started. Monitoring path ahead.',
      isCritical: false,
      proximity: ProximityLevel.caution,
      bypassCooldown: true,
    );

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (!_isScanning || _isProcessingFrame) return;
        _isProcessingFrame = true;
        try {
          debugPrint('[VisionMax] frame ${image.width}x${image.height} planes=${image.planes.length}');
          final safetyResult = _detectorService.runFrameSafetyChecks(image);
          debugPrint('[VisionMax] safety: status=${safetyResult.status} lum=${safetyResult.luminance.toStringAsFixed(1)} var=${safetyResult.variance.toStringAsFixed(1)}');

          if (safetyResult.status != FrameSafetyStatus.ok &&
              safetyResult.message != null) {
            if (mounted && _isScanning) {
              setState(() {
                _detectionInstruction = safetyResult.message!;
                _currentProximity = ProximityLevel.critical;
                _currentRegion = ScreenRegion.center;
                _currentIsCritical = true;
              });
              _speakAlert(
                safetyResult.message!,
                isCritical: true,
                proximity: ProximityLevel.critical,
              );
            }
            _isProcessingFrame = false;
            return;
          }

          final detections = await _detectorService.processCameraImage(image);
          debugPrint('[VisionMax] detection count: ${detections.length}');
          final analysis = _detectorService.analyzeDetections(
            detections,
            image.width,
            image.height,
          );

          if (mounted && _isScanning) {
            setState(() {
              _detectionInstruction = analysis.instruction;
              _currentProximity = analysis.proximity;
              _currentRegion = analysis.region;
              _currentIsCritical = analysis.isCritical;
            });
            _speakAlert(
              analysis.instruction,
              isCritical: analysis.isCritical,
              proximity: analysis.proximity,
            );
          }
        } catch (e) {
          debugPrint('[VisionMax] Error processing camera frame: $e');
        } finally {
          _isProcessingFrame = false;
        }
      });
      debugPrint('[VisionMax] image stream started successfully');
    } catch (e) {
      debugPrint('[VisionMax] Error starting image stream: $e');
      _showMessage('Failed to start camera stream.', long: true);
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _stopScanning() async {
    debugPrint('[VisionMax] _stopScanning called');
    if (_cameraController != null && _isCameraInitialized) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
          debugPrint('[VisionMax] image stream stopped');
        }
      } catch (e) {
        debugPrint('[VisionMax] Error stopping image stream: $e');
      }
    }
    _showMessage('Scanning stopped');
    _speakAlert(
      'Scanning stopped.',
      isCritical: false,
      proximity: ProximityLevel.caution,
      bypassCooldown: true,
    );
    if (mounted) {
      setState(() {
        _isScanning = false;
        _detectionInstruction = 'Ready';
        _currentProximity = ProximityLevel.safe;
        _currentRegion = ScreenRegion.center;
        _currentIsCritical = false;
      });
    }
  }

  Future<void> _speakAlert(
    String text, {
    required bool isCritical,
    required ProximityLevel proximity,
    bool bypassCooldown = false,
  }) async {
    final now = DateTime.now();
    double alertCooldown = 2.0;
    try {
      final box = Hive.box('settings');
      alertCooldown =
          (box.get('alertCooldown', defaultValue: 2.0) as num).toDouble();
    } catch (e) {
      debugPrint('[VisionMax] Hive box read error in _speakAlert: $e');
    }

    debugPrint('[VisionMax] speakAlert: "$text" crit=$isCritical prox=$proximity cd=$alertCooldown');

    final cooldownDuration = Duration(milliseconds: (alertCooldown * 1000).round());

    if (!isCritical && !bypassCooldown) {
      final timeSinceLastNonCritical = now.difference(_lastNonCriticalSpokenTime);
      if (timeSinceLastNonCritical < cooldownDuration) {
        debugPrint('[VisionMax] suppressed by cooldown (time since last non-critical: ${timeSinceLastNonCritical.inMilliseconds}ms < ${cooldownDuration.inMilliseconds}ms)');
        return;
      }
      if (_lastSpokenInstruction == text &&
          now.difference(_lastSpokenTime) < cooldownDuration * 2) {
        debugPrint('[VisionMax] suppressed exact duplicate');
        return;
      }
    }

    _lastSpokenInstruction = text;
    _lastSpokenTime = now;
    if (!isCritical) {
      _lastNonCriticalSpokenTime = now;
    }
    try {
      await _triggerHapticFeedback(proximity: proximity);
      if (isCritical) {
        try {
          await _flutterTts.stop();
        } catch (_) {}
      }
      if (!_isTtsInitialized) {
        debugPrint('[VisionMax] TTS still not ready; waiting 200ms');
        await Future.delayed(const Duration(milliseconds: 200));
      }
      final ttsResult = await _flutterTts.speak(text);
      debugPrint('[VisionMax] flutterTts.speak result: $ttsResult');
    } catch (e) {
      debugPrint('[VisionMax] TTS speak error: $e');
    }
  }

  Future<void> _triggerHapticFeedback(
      {required ProximityLevel proximity}) async {
    try {
      bool isEnabled = true;
      try {
        final box = Hive.box('settings');
        isEnabled =
            box.get('isHapticFeedback', defaultValue: true) as bool;
      } catch (e) {
        debugPrint('[VisionMax] Hive haptic read error: $e');
      }
      if (!isEnabled) {
        debugPrint('[VisionMax] haptic disabled by setting');
        return;
      }
      if (proximity == ProximityLevel.safe) return;

      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) {
        debugPrint('[VisionMax] no vibrator available');
        return;
      }

      bool hasAmplitude = false;
      try {
        hasAmplitude = await Vibration.hasAmplitudeControl();
      } catch (_) {}

      if (proximity == ProximityLevel.critical) {
        if (hasAmplitude && Platform.isAndroid) {
          await Vibration.vibrate(
            pattern: [0, 150, 60, 150, 60, 150],
            intensities: [0, 255, 0, 255, 0, 255],
          );
        } else {
          await Vibration.vibrate(pattern: [0, 150, 60, 150, 60, 150]);
        }
        debugPrint('[VisionMax] critical haptic fired');
      } else {
        if (hasAmplitude && Platform.isAndroid) {
          await Vibration.vibrate(duration: 100, amplitude: 200);
        } else {
          await Vibration.vibrate(duration: 100);
        }
        debugPrint('[VisionMax] caution haptic fired');
      }
    } catch (e) {
      debugPrint('[VisionMax] Haptic feedback error: $e');
    }
  }

  String _regionLabel(ScreenRegion region) {
    switch (region) {
      case ScreenRegion.left:
        return 'Left';
      case ScreenRegion.center:
        return 'Center';
      case ScreenRegion.right:
        return 'Right';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isWeb
          ? null
          : AppBar(
              centerTitle: true,
              title: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Vision - Max',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ),
              backgroundColor: theme.scaffoldBackgroundColor,
              foregroundColor: theme.colorScheme.onSurface,
              elevation: 0,
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              children: [
                if (_isScanning && _cameraController != null && _isCameraInitialized)
                  Offstage(
                    offstage: true,
                    child: SizedBox(
                      width: 1,
                      height: 1,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 3),
                      
                      _DashboardCard(
                        title: 'Camera Status',
                        status: _isScanning ? 'Active' : 'Inactive',
                        subtitle: _isCameraInitialized
                            ? (_isScanning ? 'Monitoring path' : 'Tap to start scanning')
                            : 'Initializing camera...',
                        onTap: _toggleScanning,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _DashboardCard(
                        title: 'Detection',
                        status: _currentIsCritical
                            ? 'Critical Alert'
                            : (_currentProximity == ProximityLevel.caution
                                ? 'Caution'
                                : (_isScanning ? 'Monitoring' : 'TTS ready')),
                        subtitle: _isScanning
                            ? '${_regionLabel(_currentRegion)} - $_detectionInstruction'
                            : (_isTtsInitialized ? 'Tap Start to begin' : 'Initializing voice...'),
                        onTap: () {
                          if (_isScanning) {
                            _speakAlert(
                              _detectionInstruction,
                              isCritical: _currentIsCritical,
                              proximity: _currentProximity,
                              bypassCooldown: true,
                            );
                          } else {
                            _speakAlert(
                              'Ready. Tap Start Scanning to begin monitoring.',
                              isCritical: false,
                              proximity: ProximityLevel.caution,
                              bypassCooldown: true,
                            );
                          }
                        },
                      ),
                      
                      const Spacer(flex: 4),
                      
                      ElevatedButton(
                        onPressed: _toggleScanning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          _isScanning ? 'Stop Scanning' : 'Start Scanning',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String status;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.status,
    required this.subtitle,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityValue(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacityValue(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacityValue(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacityValue(0.6),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacityValue(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
