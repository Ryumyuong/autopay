import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/token_store.dart';
import '../utils/constants.dart';
import 'signup_screen.dart';
import 'main_screen.dart';
import 'main_admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // 아이디 찾기 다이얼로그용 컨트롤러
  final _findNameController = TextEditingController();
  final _findPhoneController = TextEditingController();
  final _findEmailController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _findNameController.dispose();
    _findPhoneController.dispose();
    _findEmailController.dispose();
    super.dispose();
  }

  // 아이디 찾기 다이얼로그 (Android와 동일)
  void _showFindIdDialog() {
    _findNameController.clear();
    _findPhoneController.clear();
    _findEmailController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('아이디 찾기', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _findNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _findInputDecoration('이름'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _findPhoneController,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.phone,
                decoration: _findInputDecoration('전화번호'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _findEmailController,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.emailAddress,
                decoration: _findInputDecoration('이메일'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => _findUserId(context),
            child: const Text('찾기', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  InputDecoration _findInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> _findUserId(BuildContext dialogContext) async {
    final name = _findNameController.text.trim();
    final phone = _findPhoneController.text.trim();
    final email = _findEmailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      _showError('모든 항목을 입력해주세요.');
      return;
    }

    try {
      final result = await _apiService.findUserId(name, phone, email);
      final foundId = result['id'];

      Navigator.pop(dialogContext);

      if (foundId != null && foundId.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text('아이디 찾기 결과', style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              '회원님의 아이디는\n\n$foundId\n\n입니다.',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
      } else {
        _showError('일치하는 회원 정보가 없습니다.');
      }
    } catch (e) {
      _showError('일치하는 회원 정보가 없습니다.');
    }
  }

  // 비밀번호 찾기 다이얼로그 (Android와 동일 - 전화 연결)
  void _showFindPasswordDialog() {
    const phoneNumber = '010-4667-9776';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('비밀번호 찾기', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          '비밀번호 관련 문의는\n전화로 안내해드립니다.\n\n$phoneNumber',
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _makePhoneCall(phoneNumber);
            },
            child: const Text('전화걸기', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _login({bool isAdmin = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = LoginRequest(
        id: _idController.text.trim(),
        password: _passwordController.text,
      );

      final response = await _apiService.login(request);

      if (response.success && response.person != null) {
        final person = response.person!;

        await TokenStore.saveLoginInfo(
          userId: person.id ?? '',
          userName: person.name ?? '',
          rate: person.rate ?? 'USER',
        );

        // FCM 토큰 등록 (Android와 동일)
        final firebaseService = FirebaseService();
        if (person.isAdmin) {
          await firebaseService.registerAdminToken();
        } else {
          await firebaseService.registerUserToken();
        }
        firebaseService.listenToTokenRefresh();

        if (!mounted) return;

        if (person.isAdmin) {
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
        _showError(response.message ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // 로고 이미지
                Center(
                  child: Image.asset(
                    AppAssets.logo,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),

                // 아이디 입력
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    controller: _idController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('아이디'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '아이디를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('비밀번호').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textHint,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // 로그인 버튼들
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // 사업자회원 로그인 버튼 (검은색)
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _login(isAdmin: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonBlack,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '사업자회원\n로그인',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 일반회원 로그인 버튼 (파란색)
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _login(isAdmin: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '일반회원\n로그인',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 회원가입 안내
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '아직 회원이 아니신가요?',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          ' 회원가입 ',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        '바로가기',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 아이디 찾기 | 비밀번호 찾기 (Android와 동일)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _showFindIdDialog,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            '아이디 찾기',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        '|',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 20,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showFindPasswordDialog,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            '비밀번호 찾기',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      labelText: hint,
      labelStyle: const TextStyle(color: AppColors.textHint),
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}
