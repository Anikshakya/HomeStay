import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/view/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


// Commands to change password
//mysql -u root -p
// ALTER USER 'root'@'localhost' IDENTIFIED BY '1234';
// FLUSH PRIVILEGES;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HotelManagerApp());
}

class HotelManagerApp extends StatelessWidget {
  const HotelManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Hotel Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 2,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
        ),
      ),
      home: MainScreen(),
    );
  }
}
