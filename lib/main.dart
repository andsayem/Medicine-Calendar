import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/medicine_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => MedicineProvider()..initialize(),
      child: const MyMedicineNoteApp(),
    ),
  );
}

class MyMedicineNoteApp extends StatelessWidget {
  const MyMedicineNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'Medi Reminder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
