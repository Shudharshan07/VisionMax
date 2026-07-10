import 'package:visionmax/utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visionmax/themes/theme_cubit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterTts _tts = FlutterTts();

  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  double _alertCooldown = 2.0;
  bool _isHapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = Hive.box('settings');
      setState(() {
        _speechRate = (box.get('speechRate', defaultValue: 0.5) as num).toDouble();
        _pitch = (box.get('pitch', defaultValue: 1.0) as num).toDouble();
        _volume = (box.get('volume', defaultValue: 1.0) as num).toDouble();
        _alertCooldown = (box.get('alertCooldown', defaultValue: 2.0) as num).toDouble();
        _isHapticFeedback = box.get('isHapticFeedback', defaultValue: true) as bool;
      });
      await _applyTtsSettings();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = Hive.box('settings');
      await box.put('speechRate', _speechRate);
      await box.put('pitch', _pitch);
      await box.put('volume', _volume);
      await box.put('alertCooldown', _alertCooldown);
      await box.put('isHapticFeedback', _isHapticFeedback);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> _applyTtsSettings() async {
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
    } catch (e) {
      debugPrint('Error applying TTS settings: $e');
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _speechRate = 0.5;
      _pitch = 1.0;
      _volume = 1.0;
      _alertCooldown = 2.0;
      _isHapticFeedback = true;
    });
    await _applyTtsSettings();
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isWeb
        ? null
        : AppBar(
            centerTitle: true,
            title: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Settings',
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
      drawer: null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                // Appearance section
                _SectionLabel('Appearance'),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: isDark ? Colors.teal : Colors.orange,
                  title: isDark ? 'Dark Mode' : 'Light Mode',
                  subtitle: isDark
                      ? 'Switch to light appearance'
                      : 'Switch to dark appearance',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacityValue(0.4),
                  ),
                  onTap: () => context.read<ThemeCubit>().toggleTheme(),
                ),
                const SizedBox(height: 24),

                // Voice section
                _SectionLabel('Voice'),
                const SizedBox(height: 12),
                _SettingsSliderTile(
                  icon: Icons.speed_rounded,
                  iconColor: Colors.blue,
                  title: 'Speech Rate',
                  subtitle: _speechRate.toStringAsFixed(1),
                  value: _speechRate,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() => _speechRate = value);
                    _applyTtsSettings();
                  },
                ),
                _SettingsSliderTile(
                  icon: Icons.tune_rounded,
                  iconColor: Colors.deepPurple,
                  title: 'Pitch',
                  subtitle: _pitch.toStringAsFixed(1),
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (value) {
                    setState(() => _pitch = value);
                    _applyTtsSettings();
                  },
                ),
                _SettingsSliderTile(
                  icon: Icons.volume_up_rounded,
                  iconColor: Colors.green,
                  title: 'Volume',
                  subtitle: _volume.toStringAsFixed(1),
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() => _volume = value);
                    _applyTtsSettings();
                  },
                ),
                const SizedBox(height: 24),

                // Detection section
                _SectionLabel('Detection'),
                const SizedBox(height: 12),
                _SettingsSliderTile(
                  icon: Icons.timer_rounded,
                  iconColor: Colors.orange,
                  title: 'Alert Cooldown',
                  subtitle: '${_alertCooldown.toStringAsFixed(1)}s',
                  value: _alertCooldown,
                  min: 1.0,
                  max: 5.0,
                  onChanged: (value) {
                    setState(() => _alertCooldown = value);
                  },
                ),
                _SettingsTile(
                  icon: Icons.vibration_rounded,
                  iconColor: Colors.pink,
                  title: 'Haptic Feedback',
                  subtitle: _isHapticFeedback ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _isHapticFeedback,
                    activeThumbColor: theme.colorScheme.primary,
                    onChanged: (value) {
                      setState(() => _isHapticFeedback = value);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Actions section
                _SectionLabel('Actions'),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.record_voice_over_rounded,
                  iconColor: theme.colorScheme.primary,
                  title: 'Test TTS',
                  subtitle: 'Play a sample announcement',
                  trailing: Icon(
                    Icons.play_arrow_rounded,
                    color: theme.colorScheme.onSurface.withOpacityValue(0.4),
                  ),
                  onTap: () {
                    _tts.speak('This is a test announcement.');
                  },
                ),
                _SettingsTile(
                  icon: Icons.restart_alt_rounded,
                  iconColor: theme.colorScheme.error,
                  title: 'Reset to Default',
                  subtitle: 'Restore all settings to defaults',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacityValue(0.4),
                  ),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _resetToDefault();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Settings reset to default')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _saveSettings();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Settings saved')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withOpacityValue(0.4),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityValue(0.05),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacityValue(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacityValue(
                            0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSliderTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SettingsSliderTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityValue(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacityValue(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacityValue(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.primary.withOpacityValue(0.15),
                thumbColor: theme.colorScheme.primary,
                overlayColor: theme.colorScheme.primary.withOpacityValue(0.1),
                trackHeight: 4,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: 10,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
