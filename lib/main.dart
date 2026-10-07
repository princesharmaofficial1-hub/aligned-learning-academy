import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/course_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'services/academic_torrents_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'theme/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only: every screen in this app is a vertical list/detail layout.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge with transparent system bars. Icon brightness is *not*
  // forced globally: each screen declares it (AppBar theme or AnnotatedRegion)
  // so light mode gets dark icons and dark mode gets light icons.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final storageService = StorageService();
  await storageService.init();

  final academicTorrentsService = AcademicTorrentsService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService.prefs)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseProvider(academicTorrentsService, storageService)
            ..loadCourses(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesProvider(storageService),
        ),
      ],
      child: const AcademicLearningApp(),
    ),
  );
}

class AcademicLearningApp extends StatelessWidget {
  const AcademicLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Aligned Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      themeAnimationDuration: AppMotion.normal,
      themeAnimationCurve: AppMotion.emphasized,
      scrollBehavior: const _AppScrollBehavior(),
      builder: (context, child) {
        // Clamp accessibility text scaling: the dense layout uses a compact
        // baseline, and unbounded scaling causes overflow on small phones.
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.25,
        );

        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              clamped.scale(1.0) * settings.textScale,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}

/// Keeps the platform scroll feel consistent with the app's cinematic motion.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
