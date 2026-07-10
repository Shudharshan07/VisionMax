import 'package:visionmax/utils/color_extensions.dart';
import 'package:visionmax/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  List<Widget> get _pages => [const HomeDashboardPage(), const SettingsPage()];

  @override
  void initState() {
    super.initState();
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
          appBar: isWeb
              ? null
              : AppBar(
                  title: Text(
                    'Vision - Max',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  backgroundColor: theme.scaffoldBackgroundColor,
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: 0,
                ),
          drawer: isWeb
              ? null
              : Drawer(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _SidebarItem(
                          icon: FontAwesomeIcons.house,
                          label: 'Home',
                          selected: _selectedIndex == 0,
                          onTap: () {
                            Navigator.pop(context);
                            _onItemTapped(HomeTab.dashboard);
                          },
                        ),
                        _SidebarItem(
                          icon: FontAwesomeIcons.gear,
                          label: 'Settings',
                          selected: _selectedIndex == HomeTab.settings.index,
                          onTap: () {
                            Navigator.pop(context);
                            _onItemTapped(HomeTab.settings);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_selectedIndex),
                        child: _pages[_selectedIndex],
                      ),
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
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  CameraController? _cameraController;
  late final ObjectDetectorService _detectorService;
  late final FlutterTts _flutterTts;

  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isProcessingFrame = false;

  String _detectionInstruction = 'Ready';
  String _lastSpokenInstruction = '';
  DateTime _lastSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));

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
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
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

  void _startScanning() async {
    if (_cameraController == null || !_isCameraInitialized) {
      await _initializeCamera();
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not ready. Check permissions.')),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _detectionInstruction = 'Ready';
    });

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (!_isScanning || _isProcessingFrame) return;
        _isProcessingFrame = true;
        try {
          final detections = await _detectorService.processCameraImage(image);
          final resultString = _detectorService.analyzeDetections(
            detections,
            image.width,
            image.height,
          );

          if (mounted && _isScanning) {
            setState(() {
              _detectionInstruction = resultString;
            });
            _speakInstruction(resultString);
          }
        } catch (e) {
          debugPrint('Error processing camera frame: $e');
        } finally {
          _isProcessingFrame = false;
        }
      });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _stopScanning() async {
    if (_cameraController != null && _isCameraInitialized) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isScanning = false;
        _detectionInstruction = 'Ready';
      });
    }
  }

  Future<void> _speakInstruction(String text) async {
    final now = DateTime.now();
    // Throttle voice announcements to avoid overlap/noise
    if (_lastSpokenInstruction == text &&
        now.difference(_lastSpokenTime) < const Duration(seconds: 3)) {
      return;
    }
    _lastSpokenInstruction = text;
    _lastSpokenTime = now;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                        subtitle: 'Tap to start',
                        onTap: _toggleScanning,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _DashboardCard(
                        title: 'Detection',
                        status: 'TTS ready',
                        subtitle: _isScanning ? _detectionInstruction : 'Ready',
                        onTap: () {
                          if (_isScanning) {
                            _speakInstruction(_detectionInstruction);
                          } else {
                            _speakInstruction('Ready');
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
