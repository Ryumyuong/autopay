import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'login_screen.dart';
import 'charge_screen.dart';
import 'usage_screen.dart';
import 'usage_admin_screen.dart';
import 'recharge_screen.dart';
import 'charge_admin_screen.dart';

class QrDisplayScreen extends StatefulWidget {
  const QrDisplayScreen({super.key});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  final _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Person? _person;
  bool _isLoading = true;
  String _userName = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      _userId = await TokenStore.getUserId() ?? '';
      _userName = await TokenStore.getUserName() ?? '';

      if (_userId.isNotEmpty) {
        _person = await _apiService.getPerson(_userId);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('로그아웃', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('로그아웃 하시겠습니까?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TokenStore.clearAll();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  bool get _isAdmin => _person?.rate == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    // ADMIN인 경우 다크 테마
    final backgroundColor = _isAdmin ? AppColors.primaryDark : AppColors.background;
    final textColor = _isAdmin ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
          : SafeArea(
              child: Column(
                children: [
                  // 상단 바
                  _buildTopBar(textColor),

                  const Spacer(),

                  // QR 코드 영역
                  _buildQrCode(),

                  const SizedBox(height: 24),

                  // QR 안내 텍스트
                  Text(
                    '위의 QR을 결제자에게 보여주세요',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),

                  const Spacer(),

                  // 닫기 버튼
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                          ),
                        ),
                        child: const Text(
                          '닫기',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTopBar(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isAdmin ? Colors.white.withOpacity(0.1) : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: textColor),
            ),
          ),
          // 로고
          Image.asset(
            _isAdmin ? AppAssets.logoWhite : AppAssets.logos,
            width: 70,
            height: 50,
            fit: BoxFit.contain,
          ),
          // 빈 공간 (균형 맞추기)
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
    // QR 코드 표시 (딥링크 URL 포함)
    final deepLink = 'autopay://payment?user_id=$_userId';

    return Container(
      width: 280,
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR 코드 placeholder (실제로는 qr_flutter 패키지 사용)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: CustomPaint(
                painter: QrCodePainter(deepLink),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userId,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.cardBackground,
      width: 280,
      child: Column(
        children: [
          // 헤더
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
            color: AppColors.primaryDark,
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 36, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_person?.name ?? _userName} 님',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatPoint(_person?.point ?? 0),
                        style: const TextStyle(
                          color: AppColors.pointGold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 메뉴 아이템들
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem('홈페이지 바로가기', Icons.language, () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem('사용 내역 조회', Icons.history, () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _isAdmin ? const UsageAdminScreen() : const UsageScreen(),
                    ),
                  );
                }),
                _buildDrawerItem(
                  _isAdmin ? '포인트 정산' : '포인트 충전',
                  Icons.account_balance_wallet,
                  () {
                    Navigator.pop(context);
                    if (_userId == 'admin') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChargeAdminScreen()));
                    } else if (_isAdmin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RechargeScreen(
                            userName: _userId,
                            currentPoints: _person?.point ?? 0,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChargeScreen(
                            userName: _userId,
                            currentPoints: _person?.point ?? 0,
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildDrawerItem('포인트 가맹점', Icons.store, () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem('고객센터', Icons.support_agent, () {
                  Navigator.pop(context);
                }),
                const Divider(color: AppColors.divider),
                _buildDrawerItem('로그아웃', Icons.logout, _logout),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}

// 간단한 QR 코드 페인터 (실제로는 qr_flutter 패키지 사용 권장)
class QrCodePainter extends CustomPainter {
  final String data;

  QrCodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 간단한 QR 패턴 (실제 QR 코드가 아님, 시각적 placeholder)
    final cellSize = size.width / 21;

    // 실제 구현에서는 qr_flutter 패키지 사용
    // 여기서는 단순히 QR 코드 모양만 표시
    final pattern = _generateSimplePattern(data.hashCode);

    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        if (pattern[i][j]) {
          canvas.drawRect(
            Rect.fromLTWH(j * cellSize, i * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }

    // 위치 탐지 패턴 (모서리 3개)
    _drawFinderPattern(canvas, 0, 0, cellSize, paint);
    _drawFinderPattern(canvas, 0, 14, cellSize, paint);
    _drawFinderPattern(canvas, 14, 0, cellSize, paint);
  }

  List<List<bool>> _generateSimplePattern(int seed) {
    final pattern = List.generate(21, (_) => List.filled(21, false));
    final random = seed.abs();

    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        // 위치 탐지 패턴 영역 건너뛰기
        if ((i < 7 && j < 7) || (i < 7 && j > 13) || (i > 13 && j < 7)) {
          continue;
        }
        pattern[i][j] = ((random + i * 17 + j * 31) % 3 == 0);
      }
    }

    return pattern;
  }

  void _drawFinderPattern(Canvas canvas, int row, int col, double cellSize, Paint paint) {
    // 외부 검은색 테두리
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        if (i == 0 || i == 6 || j == 0 || j == 6 ||
            (i >= 2 && i <= 4 && j >= 2 && j <= 4)) {
          canvas.drawRect(
            Rect.fromLTWH(
              (col + j) * cellSize,
              (row + i) * cellSize,
              cellSize,
              cellSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
