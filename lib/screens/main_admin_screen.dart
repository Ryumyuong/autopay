import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'login_screen.dart';
import 'charge_screen.dart';
import 'payment_screen.dart';
import 'recharge_screen.dart';
import 'usage_admin_screen.dart';
import 'qr_scan_screen.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

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
        backgroundColor: AppColors.primaryDark,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          '${AppStrings.appName} (관리자)',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadUserData,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 포인트 카드
                    _buildPointCard(),
                    const SizedBox(height: 24),

                    // 메뉴 그리드
                    _buildMenuGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.accent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  _person?.company ?? _person?.name ?? _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppDimens.fontXLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _userId,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppDimens.fontMedium,
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
              ],
            ),
          ),
          _buildDrawerItem(Icons.home, '홈', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.history, '거래 내역', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UsageAdminScreen()));
          }),
          _buildDrawerItem(Icons.qr_code_scanner, 'QR 스캔', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
          }),
          const Divider(color: AppColors.textHint),
          _buildDrawerItem(Icons.logout, '로그아웃', _logout, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary)),
      onTap: onTap,
    );
  }

  Widget _buildPointCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D3436), Color(0xFF636E72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '보유 포인트',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppDimens.fontMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppDimens.fontSmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatPoint(_person?.point ?? 0),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _person?.company ?? _person?.name ?? _userName,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimens.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menus = [
      _MenuItemData(Icons.add_circle_outline, '충전 신청', AppColors.charge, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChargeScreen(
            userName: _userId,
            currentPoints: _person?.point ?? 0,
          ),
        )).then((_) => _loadUserData());
      }),
      _MenuItemData(Icons.payment, '결제하기', AppColors.buttonPrimary, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PaymentScreen(
            userName: _userId,
            userDisplayName: _person?.company ?? _person?.name ?? _userName,
            currentPoints: _person?.point ?? 0,
          ),
        )).then((_) => _loadUserData());
      }),
      _MenuItemData(Icons.account_balance_wallet, '정산하기', AppColors.payment, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => RechargeScreen(
            userName: _userId,
            currentPoints: _person?.point ?? 0,
          ),
        )).then((_) => _loadUserData());
      }),
      _MenuItemData(Icons.qr_code_scanner, 'QR 스캔', AppColors.warning, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
      }),
      _MenuItemData(Icons.history, '거래 내역', AppColors.textSecondary, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UsageAdminScreen()));
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final item = menus[index];
        return _buildMenuItem(item);
      },
    );
  }

  Widget _buildMenuItem(_MenuItemData item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          border: Border.all(color: item.color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppDimens.fontMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  _MenuItemData(this.icon, this.title, this.color, this.onTap);
}
