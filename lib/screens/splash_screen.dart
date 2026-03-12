import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
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
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // 버전 체크
      final needsUpdate = await _checkVersion();
      if (needsUpdate) return; // 업데이트 다이얼로그 표시 중

      // 로그인 상태 확인 후 화면 이동
      _navigateToNextScreen();
    } catch (e) {
      debugPrint('Splash screen error: $e');
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  /// 서버에서 최신 버전을 조회하여 업데이트 필요 여부 확인
  Future<bool> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.5"
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final versionData = await _apiService.getLatestVersion();
      final latestVersion = versionData['version'] as String? ?? '';
      final latestBuildNumber = (versionData['buildNumber'] as num?)?.toInt() ?? 0;

      if (!mounted) return false;

      final isOutdated = _isVersionOutdated(currentVersion, latestVersion) ||
          currentBuildNumber < latestBuildNumber;

      if (isOutdated) {
        _showForceUpdateDialog(latestVersion);
        return true;
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
      // 버전 체크 실패 시 그냥 진행
    }
    return false;
  }

  /// 버전 문자열 비교 (예: "1.0.4" < "1.0.5")
  bool _isVersionOutdated(String current, String latest) {
    if (latest.isEmpty) return false;

    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;

    for (int i = 0; i < maxLen; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (c < l) return true;
      if (c > l) return false;
    }
    return false;
  }

  /// 강제 업데이트 다이얼로그 (닫기 불가)
  void _showForceUpdateDialog(String latestVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            '업데이트 필요',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '새로운 버전(v$latestVersion)이 출시되었습니다.\n원활한 사용을 위해 최신 버전으로 업데이트해주세요.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openStore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  ),
                ),
                child: const Text('업데이트', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 스토어 열기
  Future<void> _openStore() async {
    final Uri storeUrl;
    if (Platform.isAndroid) {
      storeUrl = Uri.parse('market://details?id=com.auto.autopay');
    } else if (Platform.isIOS) {
      // iOS App Store ID로 변경 필요
      storeUrl = Uri.parse('https://apps.apple.com/app/id6756905219');
    } else {
      return;
    }

    try {
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to open store: $e');
    }
  }

  /// 로그인 상태 확인 후 적절한 화면으로 이동
  Future<void> _navigateToNextScreen() async {
    try {
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
        if (pendingPayeeId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainAdminScreen(initialPayeeId: pendingPayeeId),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainAdminScreen()),
          );
        }
      } else if (isLoggedIn) {
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
      debugPrint('Navigation error: $e');
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
