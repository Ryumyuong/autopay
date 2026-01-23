import 'package:flutter/material.dart';
import '../services/token_store.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'main_admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isLoggedIn = await TokenStore.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      final rate = await TokenStore.getUserRate();
      if (!mounted) return;

      if (rate == 'ADMIN') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAdminScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지 (이미지가 없으면 텍스트로 대체)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'AP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppDimens.fontTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.buttonPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
