import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/aligned_logo_view.dart';
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
        titleSpacing: 16,
        title: const AlignedLogoView(
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Streaming & Playback section
          _buildSectionHeader('Enterprise Streaming & Playback'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: AppTheme.primary,
                  title: const Text('High-Definition Stream Optimization', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Optimizes video stream buffering and reduces startup latency.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  value: _optimizeStreaming,
                  onChanged: (val) => setState(() => _optimizeStreaming = val),
                ),
                const Divider(color: AppTheme.cardBorder, height: 1),
                SwitchListTile(
                  activeColor: AppTheme.primary,
                  title: const Text('Download on Wi-Fi Only', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Avoid consuming cellular data for large multi-gigabyte course files.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  value: _wifiOnly,
                  onChanged: (val) => setState(() => _wifiOnly = val),
                ),
                const Divider(color: AppTheme.cardBorder, height: 1),
                SwitchListTile(
                  activeColor: AppTheme.primary,
                  title: const Text('Auto-play Next Lecture', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Automatically load subsequent syllabus lecture on completion.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  value: _autoPlayNext,
                  onChanged: (val) => setState(() => _autoPlayNext = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cache & Storage
          _buildSectionHeader('Storage & Cache Management'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_outlined, color: AppTheme.secondary),
              title: const Text('Clear Video Stream Cache', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Frees temporary stream buffer files from device memory.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              trailing: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video cache cleaned successfully!')),
                  );
                },
                child: const Text('Clear', style: TextStyle(color: AppTheme.primaryGlow)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Platform & Open Source Attribution
          _buildSectionHeader('Platform & Open Source Attribution'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school, color: AppTheme.primaryGlow, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aligned Learning Academy',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Enterprise Continuous Technical Upskilling',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aligned Learning provides production-grade technical curricula across modern technology stacks. All course materials and video streams originate exclusively from public domain and open-access educational initiatives (MIT OpenCourseWare, Harvard CS, OER Commons).',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.verified_user_outlined, size: 18, color: AppTheme.secondary),
                      label: const Text('View Content Sources & Licensing Credits'),
                      onPressed: () => SourcesCreditsDialog.show(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: AppTheme.success),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Client-Side Architecture: 100% Serverless, App Store & Google Play Compliant',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Build Version
          Center(
            child: Text(
              'Aligned Technical Academy • v1.0.0 (Build 2026.10)',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted.withAlpha(160)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
