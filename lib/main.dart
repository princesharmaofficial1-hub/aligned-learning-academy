import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/course_provider.dart';
import 'providers/notes_provider.dart';
import 'screens/splash_screen.dart';
import 'services/academic_torrents_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless edge-to-edge dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize client-side persistent storage
  final storageService = StorageService();
  await storageService.init();

  final academicTorrentsService = AcademicTorrentsService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CourseProvider(academicTorrentsService, storageService)..loadCourses(),
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
    return MaterialApp(
      title: 'Aligned Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

