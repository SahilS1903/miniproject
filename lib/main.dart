import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dataset_selection_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BotDetectionApp());
}

class BotDetectionApp extends StatelessWidget {
  const BotDetectionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bot Detection App',
      theme: AppTheme.darkTheme,
      home: const DatasetSelectionScreen(),
    );
  }
}
