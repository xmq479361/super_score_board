import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/start_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 设置全屏和方向
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  runApp(ScoreApp(storageService: storageService));
}

class ScoreApp extends StatelessWidget {
  final StorageService storageService;

  const ScoreApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '计分板',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.blue,
        appBarTheme: const AppBarTheme(
            scrolledUnderElevation: 0,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
            toolbarHeight: 44,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            backgroundColor: Colors.transparent,
            elevation: 2),
      ),
      debugShowCheckedModeBanner: false,
      home: StartScreen(storageService: storageService),
    );
  }
}
