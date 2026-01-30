import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'login_screen.dart';
import 'charge_screen.dart';
import 'charge_admin_screen.dart';
import 'payment_screen.dart';
import 'recharge_screen.dart';
import 'usage_admin_screen.dart';
import 'qr_scan_screen.dart';

class MainAdminScreen extends StatefulWidget {
  final String? initialPayeeId;

  const MainAdminScreen({super.key, this.initialPayeeId});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  final _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Person? _person;
  bool _isLoading = true;
  String _userName = '';
  String _userId = '';

  // 관리자 화면 전용 색상
  static const Color _adminBackground = Color(0xFF1A2332);

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

      if (_userId.isNotEmpty && mounted) {
        _person = await _apiService.getPerson(_userId);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);

        // 딥링크로 결제 요청이 있으면 결제 화면으로 이동
        if (widget.initialPayeeId != null && _person != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  userName: _userId,
                  userDisplayName: _userName,
                  currentPoints: _person!.point ?? 0,
                  initialPayeeId: widget.initialPayeeId,
                ),
              ),
            );
          });
        }
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

    if (confirm == true && mounted) {
      // 서버에서 FCM 토큰 삭제 (현재 기기 토큰과 일치할 때만)
      try {
        final userId = await TokenStore.getUserId();
        if (userId != null && userId.isNotEmpty) {
          final currentToken = await FirebaseMessaging.instance.getToken();
          if (currentToken != null) {
            await _apiService.unregisterUserDevice(userId, currentToken);
            debugPrint('FCM 토큰 삭제 완료');
          }
        }
      } catch (e) {
        debugPrint('FCM 토큰 삭제 실패: $e');
      }

      await TokenStore.clearAll();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('회원탈퇴', style: TextStyle(color: AppColors.error)),
        content: const Text(
          '정말로 탈퇴하시겠습니까?\n탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('탈퇴하기', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _apiService.withdrawUser(_userId);
        if (!mounted) return;

        // 관리자에게 탈퇴 알림 전송
        try {
          await _apiService.notifyWithdraw(_userId, _person?.company ?? _person?.name ?? _userName);
        } catch (e) {
          debugPrint('Withdraw notification failed: $e');
        }

        await TokenStore.clearAll();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원탈퇴가 완료되었습니다')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원탈퇴 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _adminBackground,
      endDrawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textWhite))
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 상단 바
                    _buildTopBar(),

                    // 메인 콘텐츠
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 인사말
                          _buildGreeting(),
                          const SizedBox(height: 20),

                          // 포인트결제/충전 카드
                          _buildMainCards(),
                          const SizedBox(height: 25),

                          // 링크/계좌번호 카드
                          _buildSecondaryCards(),
                          const SizedBox(height: 25),

                          // 배너
                          _buildBanner(),
                          const SizedBox(height: 40),

                          // 전화 이미지
                          _buildTelImage(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 50, bottom: 16),
      color: _adminBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),
          // 로고 (흰색)
          Image.asset(
            AppAssets.logoWhite,
            width: 70,
            height: 80,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          // 메뉴 버튼
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: const Icon(Icons.menu, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Row(
      children: [
        Text(
          _person?.company ?? _person?.name ?? _userName,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          ' 대표님 안녕하세요!',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCards() {
    return Row(
      children: [
        // 포인트결제 카드
        Expanded(
          child: GestureDetector(
            onTap: () async {
              // QR 스캔 화면으로 먼저 이동
              final scannedUserId = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const QrScanScreen()),
              );

              // 스캔된 ID가 있으면 결제 화면으로 이동
              if (scannedUserId != null && scannedUserId.isNotEmpty && mounted) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    userName: _userId,
                    userDisplayName: _person?.company ?? _person?.name ?? _userName,
                    currentPoints: _person?.point ?? 0,
                    initialPayeeId: scannedUserId,
                  ),
                )).then((_) => _loadUserData());
              }
            },
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  AppAssets.pointa,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 포인트충전 카드
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChargeScreen(
                  userName: _userId,
                  currentPoints: _person?.point ?? 0,
                ),
              )).then((_) => _loadUserData());
            },
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  AppAssets.chargea,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryCards() {
    return Row(
      children: [
        // 링크 카드 (결제 링크 복사)
        Expanded(
          child: GestureDetector(
            onTap: () {
              final paymentLink = 'http://223.130.146.117:8080/pay.html?user_id=$_userId';
              Clipboard.setData(ClipboardData(text: paymentLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('결제 링크가 복사되었습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  AppAssets.link,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 계좌번호 카드
        Expanded(
          child: GestureDetector(
            onTap: () {
              const accountNumber = '3333-23-9022093';
              Clipboard.setData(const ClipboardData(text: accountNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('계좌번호가 복사되었습니다: $accountNumber'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  AppAssets.numbera,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Image.asset(
      AppAssets.addBanner,
      height: 120,
      fit: BoxFit.contain,
    );
  }

  Widget _buildTelImage() {
    return Image.asset(
      AppAssets.telImg,
      height: 120,
      fit: BoxFit.contain,
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
                // 사용자 아바타
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings, size: 36, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 16),
                // 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _person?.company ?? _person?.name ?? _userName,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '현재 보유 포인트',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 14,
                        ),
                      ),
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
                _buildDrawerItem('홈페이지 바로가기', () async {
                  Navigator.pop(context);
                  final url = Uri.parse('https://autoagency.cafe24.com/skin-skin1');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }),
                _buildDrawerItem('사용 내역 조회', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UsageAdminScreen()));
                }),
                _buildDrawerItem('포인트 충전', () {
                  Navigator.pop(context);
                  // admin 아이디일 때는 다른 사람 포인트 충전 화면으로 이동
                  if (_userId == 'admin') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ChargeAdminScreen(),
                    )).then((_) => _loadUserData());
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChargeScreen(
                        userName: _userId,
                        currentPoints: _person?.point ?? 0,
                      ),
                    )).then((_) => _loadUserData());
                  }
                }),
                _buildDrawerItem('포인트 정산', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RechargeScreen(
                      userName: _userId,
                      currentPoints: _person?.point ?? 0,
                    ),
                  )).then((_) => _loadUserData());
                }),
                _buildDrawerItem('포인트 가맹점', () async {
                  Navigator.pop(context);
                  final url = Uri.parse('https://autoagency.cafe24.com/skin-skin1/board/PARTNERS/4/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }),
                _buildDrawerItem('고객센터', () async {
                  Navigator.pop(context);
                  final url = Uri.parse('tel:010-4667-9776');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                }),
                const Divider(color: AppColors.divider),
                _buildDrawerItem('로그아웃', _logout),
                _buildDrawerItem('회원탈퇴', _deleteAccount, isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
