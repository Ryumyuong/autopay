import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'login_screen.dart';
import 'charge_screen.dart';
import 'payment_screen.dart';
import 'usage_screen.dart';
import 'qr_scan_screen.dart';
import 'recharge_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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

    if (confirm == true) {
      try {
        await _apiService.deleteUser(_userId);
        await TokenStore.clearAll();
        if (!mounted) return;
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
      backgroundColor: AppColors.background,
      endDrawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
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
                          const SizedBox(height: 40),

                          // 계좌번호 카드
                          _buildAccountCard(),
                          const SizedBox(height: 40),

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
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),
          // 로고
          Image.asset(
            AppAssets.logos,
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
          _person?.name ?? _userName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          '님 안녕하세요!',
          style: TextStyle(
            color: AppColors.textPrimary,
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
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  userName: _userId,
                  userDisplayName: _person?.name ?? _userName,
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
                  AppAssets.point,
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
                  AppAssets.charge,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          AppAssets.number,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
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
                  child: const Icon(Icons.person, size: 36, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 16),
                // 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _person?.name ?? _userName,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                _buildDrawerItem('홈페이지 바로가기', () {
                  Navigator.pop(context);
                  // 웹페이지로 이동
                }),
                _buildDrawerItem('사용 내역 조회', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UsageScreen()));
                }),
                _buildDrawerItem('포인트 충전', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChargeScreen(
                      userName: _userId,
                      currentPoints: _person?.point ?? 0,
                    ),
                  )).then((_) => _loadUserData());
                }),
                _buildDrawerItem('포인트 가맹점', () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem('고객센터', () {
                  Navigator.pop(context);
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
