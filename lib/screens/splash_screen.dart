import 'package:flutter/material.dart';
import '../services/token_store.dart';
import '../services/deep_link_service.dart';
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
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      bool isLoggedIn = false;
      String? rate;
      String? userId;

      try {
        isLoggedIn = await TokenStore.isLoggedIn();
        if (isLoggedIn) {
          rate = await TokenStore.getUserRate();
          userId = await TokenStore.getUserId();
        }
      } catch (e) {
        debugPrint('TokenStore error: $e');
        isLoggedIn = false;
      }

      if (!mounted) return;

      // 딥링크로 결제 요청이 있는지 확인
      final pendingPayeeId = DeepLinkService().consumePendingPaymentUserId();

      if (isLoggedIn && rate == 'ADMIN') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAdminScreen()),
        );
      } else if (isLoggedIn) {
        // 딥링크 결제 요청이 있으면 결제 화면으로 이동
        if (pendingPayeeId != null && userId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainScreen(initialPayeeId: pendingPayeeId),
            ),
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
    } catch (e) {
      debugPrint('Splash screen error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
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
