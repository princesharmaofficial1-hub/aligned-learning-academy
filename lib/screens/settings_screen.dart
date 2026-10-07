import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_components.dart';
import '../widgets/sources_credits_dialog.dart';

/// System preferences. Everything here is persisted, so the screen is a thin
/// view over [SettingsProvider] rather than a second source of truth.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: const _SettingsAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.lg,
          AppSpace.gutter,
          AppSpace.dockClearance,
        ),
        children: <Widget>[
          const _LicenseBanner(),

          // ---- Appearance ------------------------------------------------
          const SectionHeader(
            title: 'Appearance & Accessibility',
            subtitle: 'How Aligned renders and reads',
          ),
          _Group(
            children: <Widget>[
              _ThemePicker(
                value: settings.themeMode,
                onChanged: settings.setThemeMode,
              ),
              const _GroupDivider(),
              _SwitchRow(
                icon: Icons.animation_rounded,
                color: t.violet,
                title: 'Reduce motion',
                subtitle:
                    'Shortens transitions and disables non-essential animation.',
                value: settings.reduceMotion,
                onChanged: settings.setReduceMotion,
              ),
              const _GroupDivider(),
              _TextScaleSlider(
                value: settings.textScale,
                onChanged: settings.setTextScale,
              ),
            ],
          ),

          // ---- Playback --------------------------------------------------
          const SectionHeader(
            title: 'Streaming & Playback',
            subtitle: 'Delivery and sequencing defaults',
          ),
          _Group(
            children: <Widget>[
              _SwitchRow(
                icon: Icons.hd_rounded,
                color: t.info,
                title: 'Optimise HD streaming',
                subtitle:
                    'Tunes the buffering pipeline to minimise playback latency.',
                value: settings.optimizeStreaming,
                onChanged: settings.setOptimizeStreaming,
              ),
              const _GroupDivider(),
              _SwitchRow(
                icon: Icons.wifi_rounded,
                color: t.green,
                title: 'Download on Wi-Fi only',
                subtitle:
                    'Protects cellular data when caching large video files.',
                value: settings.wifiOnly,
                onChanged: settings.setWifiOnly,
              ),
              const _GroupDivider(),
              _SwitchRow(
                icon: Icons.playlist_play_rounded,
                color: t.accent,
                title: 'Auto-play next lecture',
                subtitle:
                    'Continues to the next lecture as soon as one finishes.',
                value: settings.autoPlayNext,
                onChanged: settings.setAutoPlayNext,
              ),
            ],
          ),

          // ---- Storage ---------------------------------------------------
          const SectionHeader(
            title: 'Storage & Local Cache',
            subtitle: 'Temporary stream buffers',
          ),
          _Group(
            children: <Widget>[
              _ActionRow(
                icon: Icons.cleaning_services_rounded,
                color: t.accent,
                title: 'Clear stream cache',
                subtitle:
                    'Purges temporary stream segments and frees buffer memory.',
                actionLabel: 'Purge',
                onPressed: () => showAppSnack(
                  context,
                  'Stream cache purged',
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),

          // ---- Governance -----------------------------------------------
          const SectionHeader(
            title: 'Governance & Accreditation',
            subtitle: 'Open educational resources',
          ),
          const _GovernanceCard(),

          // ---- Build stamp -----------------------------------------------
          const SizedBox(height: AppSpace.xl),
          Center(
            child: Column(
              children: <Widget>[
                Text(
                  'Aligned Learning · v1.0.0',
                  style: context.text.labelMedium,
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: t.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      'Accelerated CDN pipeline active',
                      style: context.text.labelSmall!.copyWith(color: t.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// App bar
// =============================================================================

class _SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SettingsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return AppBar(
      backgroundColor: t.canvas,
      toolbarHeight: 60,
      titleSpacing: AppSpace.gutter,
      title: Row(
        children: <Widget>[
          AppIconTile(
            icon: Icons.tune_rounded,
            color: c.primary,
            size: 38,
            iconSize: AppIcon.sm,
            selected: true,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'SYSTEM PREFERENCES',
                  style: context.text.labelSmall!.copyWith(
                    color: c.primary,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Enterprise Settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: t.hairline),
      ),
    );
  }
}

// =============================================================================
// Banner
// =============================================================================

class _LicenseBanner extends StatelessWidget {
  const _LicenseBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return AppSurface(
      radius: AppRadius.xl,
      glow: c.primary,
      border: BorderSide(color: c.primary.withValues(alpha: 0.30)),
      gradient: LinearGradient(
        colors: <Color>[
          Color.alphaBlend(c.primary.withValues(alpha: 0.16), t.surface),
          t.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: t.surfaceRaised,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: t.hairline),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/aligned_icon.png',
                height: 32,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.business_rounded, color: t.green, size: 26),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppPill(
                  label: 'ORGANIZATION LICENSE',
                  icon: Icons.circle,
                  color: t.green,
                  dense: true,
                ),
                const SizedBox(height: AppSpace.sm),
                Text('Aligned Learning', style: context.text.titleLarge),
                const SizedBox(height: 2),
                Text(
                  'Internal technical training & upskilling platform',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Groups
// =============================================================================

/// A titled stack of related rows. One component, so every settings group has
/// identical padding, radius and divider rhythm.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(children: children),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpace.lg + 44 + AppSpace.md,
      endIndent: AppSpace.lg,
      color: context.tokens.hairline,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xs,
      ),
      secondary: AppIconTile(icon: icon, color: color, size: 44),
      title: Text(title, style: context.text.titleMedium),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: context.text.bodySmall),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: <Widget>[
          AppIconTile(icon: icon, color: color, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          AppButton(
            label: actionLabel,
            expand: false,
            variant: AppButtonVariant.outlined,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Theme picker
// =============================================================================

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  static const List<(ThemeMode, String, IconData)> _options =
      <(ThemeMode, String, IconData)>[
    (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
    (ThemeMode.light, 'Light', Icons.light_mode_rounded),
    (ThemeMode.system, 'System', Icons.brightness_auto_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Colour scheme', style: context.text.titleMedium),
          const SizedBox(height: 2),
          Text(
            'Dark is the primary experience; light is tuned for daytime reading.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: <Widget>[
              for (var i = 0; i < _options.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == _options.length - 1 ? 0 : AppSpace.sm,
                    ),
                    child: _ThemeOption(
                      label: _options[i].$2,
                      icon: _options[i].$3,
                      selected: _options[i].$1 == value,
                      onTap: () => onChanged(_options[i].$1),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      child: Material(
        color: selected
            ? c.primary.withValues(alpha: AppAlpha.soft)
            : t.surfaceRaised,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.allMd,
              border: Border.all(
                color:
                    selected ? c.primary.withValues(alpha: 0.55) : t.hairline,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: AppIcon.md,
                  color: selected ? c.primary : t.textMuted,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  label,
                  style: context.text.labelMedium!.copyWith(
                    color: selected ? c.primary : t.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

// =============================================================================
// Text scale
// =============================================================================

class _TextScaleSlider extends StatelessWidget {
  const _TextScaleSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Row(
        children: <Widget>[
          AppIconTile(
            icon: Icons.format_size_rounded,
            color: context.colors.primary,
            size: 44,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('Text size', style: context.text.titleMedium),
                    ),
                    Text(
                      '${(value * 100).round()}%',
                      style: context.text.labelMedium!.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: value,
                  min: 0.85,
                  max: 1.3,
                  divisions: 9,
                  label: '${(value * 100).round()}%',
                  onChanged: onChanged,
                ),
                Text(
                  'Applies across every screen immediately.',
                  style: context.text.bodySmall!.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Governance
// =============================================================================

class _GovernanceCard extends StatelessWidget {
  const _GovernanceCard();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return AppSurface(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIconTile(
                icon: Icons.school_rounded,
                color: t.green,
                size: 44,
                selected: true,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Aligned Learning',
                      style: context.text.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Open Educational Resources initiative',
                      style: context.text.bodySmall!.copyWith(color: t.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            'Aligned Learning delivers continuous technical upskilling '
            'to software engineers and tech leads. All instructional streams '
            'originate from public-domain and open-access university '
            'repositories — MIT OpenCourseWare, Harvard CS and OER Commons.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpace.lg),
          AppButton(
            label: 'Licensing & open content sources',
            icon: Icons.verified_rounded,
            color: t.green,
            variant: AppButtonVariant.outlined,
            onPressed: () => SourcesCreditsDialog.show(context),
          ),
        ],
      ),
    );
  }
}
