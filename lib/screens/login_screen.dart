import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
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

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // 로고
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'AP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppDimens.fontXXLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // 아이디 입력
                TextFormField(
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
                const SizedBox(height: 16),

                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('비밀번호').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
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
                const SizedBox(height: 32),

                // 로그인 버튼
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      ),
                      disabledBackgroundColor: AppColors.buttonDisabled,
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
                            AppStrings.login,
                            style: TextStyle(
                              fontSize: AppDimens.fontLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // 회원가입 버튼
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text(
                    '계정이 없으신가요? 회원가입',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppDimens.fontMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.primaryDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        borderSide: const BorderSide(color: AppColors.buttonPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingMedium,
      ),
    );
  }
}
