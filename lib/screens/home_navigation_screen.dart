import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../widgets/app_components.dart';
import 'explore_screen.dart';
import 'library_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';

/// Root shell: four primary destinations behind a frosted floating dock.
///
/// Each destination keeps its own scroll position via [IndexedStack], and
/// route changes are announced to screen readers through the dock's semantics.
class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  static const List<_NavDestination> _destinations = <_NavDestination>[
    _NavDestination(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explore',
    ),
    _NavDestination(
      icon: Icons.local_library_outlined,
      activeIcon: Icons.local_library_rounded,
      label: 'Learning',
    ),
    _NavDestination(
      icon: Icons.sticky_note_2_outlined,
      activeIcon: Icons.sticky_note_2_rounded,
      label: 'Notes',
    ),
    _NavDestination(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      label: 'Settings',
    ),
  ];

  void _select(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            context.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            context.isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            context.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const AmbientBackdrop(),
            IndexedStack(
              index: _currentIndex,
              children: const <Widget>[
                ExploreScreen(),
                LibraryScreen(),
                NotesScreen(),
                SettingsScreen(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _NavDock(
          index: _currentIndex,
          destinations: _destinations,
          onSelect: _select,
        ),
      ),
    );
  }
}

@immutable
class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavDock extends StatelessWidget {
  const _NavDock({
    required this.index,
    required this.destinations,
    required this.onSelect,
  });

  final int index;
  final List<_NavDestination> destinations;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.md,
      ),
      child: Semantics(
        container: true,
        label: 'Primary navigation',
        child: GlassSurface(
          radius: AppRadius.xl,
          blur: 22,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: <Widget>[
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavDockItem(
                    destination: destinations[i],
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDockItem extends StatelessWidget {
  const _NavDockItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: c.primary.withValues(alpha: AppAlpha.soft),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            constraints: const BoxConstraints(minHeight: AppSpace.touchTarget),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: selected
                  ? c.primary.withValues(alpha: AppAlpha.medium)
                  : Colors.transparent,
              borderRadius: AppRadius.allMd,
              border: selected
                  ? Border.all(
                      color: c.primary.withValues(alpha: 0.45),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedScale(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  scale: selected ? 1.08 : 1.0,
                  child: Icon(
                    selected ? destination.activeIcon : destination.icon,
                    size: AppIcon.md + 1,
                    color: selected ? c.primary : t.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall!.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: selected ? c.primary : t.textMuted,
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
