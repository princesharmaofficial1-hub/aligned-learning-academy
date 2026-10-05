import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/sources_credits_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _wifiOnly = true;
  bool _optimizeStreaming = true;
  bool _autoPlayNext = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background.withAlpha(240),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYSTEM PREFERENCES',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryGlow,
                  ),
                ),
                Text(
                  'Enterprise Settings',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          // Executive Organization Profile Banner
          _buildOrganizationBanner(),
          const SizedBox(height: 20),

          // Section 1: Streaming & Video Playback
          _buildSectionHeader('STREAMING & PLAYBACK ENGINE', Icons.speed_rounded),
          const SizedBox(height: 8),
          Container(
            decoration: AppTheme.luxuryCardDecoration(radius: 18),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.hd_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'High-Definition Stream Optimization',
                  subtitle: 'Optimizes video buffering pipeline and reduces playback latency.',
                  value: _optimizeStreaming,
                  onChanged: (val) => setState(() => _optimizeStreaming = val),
                ),
                const Divider(color: AppTheme.cardBorder, height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.wifi_rounded,
                  iconColor: const Color(0xFF4ED44E),
                  title: 'Download on Wi-Fi Only',
                  subtitle: 'Conserves mobile cellular bandwidth for large multi-gigabyte files.',
                  value: _wifiOnly,
                  onChanged: (val) => setState(() => _wifiOnly = val),
                ),
                const Divider(color: AppTheme.cardBorder, height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.playlist_play_rounded,
                  iconColor: const Color(0xFFA855F7),
                  title: 'Auto-play Next Syllabus Lesson',
                  subtitle: 'Sequentially transitions to subsequent video upon lecture completion.',
                  value: _autoPlayNext,
                  onChanged: (val) => setState(() => _autoPlayNext = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Storage & Cache Management
          _buildSectionHeader('STORAGE & LOCAL CACHE', Icons.storage_rounded),
          const SizedBox(height: 8),
          Container(
            decoration: AppTheme.luxuryCardDecoration(radius: 18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80), width: 1),
                    ),
                    child: const Icon(
                      Icons.cleaning_services_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clear Video Stream Cache',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Purges temporary stream segments and buffer memory.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceElevated,
                      foregroundColor: AppTheme.primaryGlow,
                      side: BorderSide(color: AppTheme.primaryGlow.withAlpha(90), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video stream cache purged successfully!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Purge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Platform Governance & Accreditation
          _buildSectionHeader('GOVERNANCE & OPEN ACCREDITATION', Icons.verified_user_rounded),
          const SizedBox(height: 8),
          Container(
            decoration: AppTheme.luxuryCardDecoration(radius: 18),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGlow.withAlpha(90), width: 1),
                      ),
                      child: const Icon(Icons.school_rounded, color: AppTheme.primaryGlow, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aligned Enterprise Academy',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Open Educational Resources (OER) Initiative',
                            style: TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Aligned Learning Academy delivers continuous technical upskilling directly to software engineers and tech leaders. All instructional video streams originate exclusively from public domain and open-access university repositories (MIT OpenCourseWare, Harvard CS, OER Commons).',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceElevated,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.cardBorder, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.verified_rounded, size: 18, color: AppTheme.secondary),
                    label: const Text(
                      'View Licensing & Open Content Sources',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => SourcesCreditsDialog.show(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Build & Enterprise Version Tag
          Center(
            child: Column(
              children: [
                Text(
                  'Aligned Learning Academy • Enterprise Edition v1.0.0',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hardware-Accelerated CDN Stream Pipeline Active',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4ED44E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2642),
            Color(0xFF0E1A2D),
            Color(0xFF080E18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGlow.withAlpha(70),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/aligned_icon.png',
                height: 32,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.business_rounded,
                  color: AppTheme.secondary,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ENTERPRISE ACTIVE LICENSE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Aligned Automation',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Internal Technical Training & Upskilling Platform',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryGlow),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppTheme.primaryGlow,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withAlpha(80), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.secondary,
            activeTrackColor: AppTheme.secondary.withAlpha(80),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surfaceElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
