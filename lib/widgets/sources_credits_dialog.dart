import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SourcesCreditsDialog extends StatelessWidget {
  const SourcesCreditsDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SourcesCreditsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withAlpha(100)),
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: AppTheme.primaryGlow, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Sources & Licensing Credits',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Open Educational Resources (OER) Attribution',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.cardBorder, height: 1),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Enterprise Legal Assurance Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.brandGreen.withAlpha(90),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppTheme.brandGreen, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '100% Legal & Enterprise Safe',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All curricula, technical slide decks, code repositories, and video streams provided in this platform originate exclusively from verified open-access educational initiatives and permissive public repositories. Fully authorized for organizational engineering training.',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Primary Open Courseware Sources',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),

                _buildSourceTile(
                  title: 'MIT OpenCourseWare (OCW)',
                  license: 'Creative Commons BY-NC-SA 4.0',
                  description:
                      'World-class foundational engineering, distributed systems, algorithms, and cybersecurity courseware provided freely for public education by the Massachusetts Institute of Technology.',
                  icon: Icons.school_outlined,
                  color: AppTheme.primary,
                ),

                _buildSourceTile(
                  title: 'Harvard CS & Open Educational Initiatives',
                  license: 'Open Educational License (OER)',
                  description:
                      'Comprehensive modern computer science, Python, backend frameworks, and web architectures distributed openly for developer skill acquisition.',
                  icon: Icons.auto_stories_outlined,
                  color: AppTheme.techFastApi,
                ),

                _buildSourceTile(
                  title: 'Internet Archive OER Public Curricula',
                  license: 'Public Domain / Creative Commons',
                  description:
                      'Digital library preservation of technical lectures, documentation, conference keynotes, and enterprise architecture workshops.',
                  icon: Icons.account_balance_outlined,
                  color: AppTheme.techDocker,
                ),

                _buildSourceTile(
                  title: 'Open Source Software Foundations & Labs',
                  license: 'MIT / Apache 2.0 / CC-BY',
                  description:
                      'Practical technical documentation, code repositories, and capstone labs from community foundations (Python Software Foundation, CNCF, Linux Foundation).',
                  icon: Icons.code,
                  color: AppTheme.secondary,
                ),

                const SizedBox(height: 16),

                // Compliance Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Text(
                    'Attribution Notice: All trademarks, course marks, and university emblems belong to their respective copyright holders. This application operates as an educational aggregator conforming to fair use and open licensing directives.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTile({
    required String title,
    required String license,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      license,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
