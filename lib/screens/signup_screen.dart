import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthController = TextEditingController();
  final _companyController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _isIdChecked = false;
  bool _isIdAvailable = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _birthController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _checkId() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showError('아이디를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exists = await _apiService.checkIdExists(id);
      setState(() {
        _isIdChecked = true;
        _isIdAvailable = !exists;
      });

      if (exists) {
        _showError('이미 사용 중인 아이디입니다.');
      } else {
        _showSuccess('사용 가능한 아이디입니다.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isIdChecked || !_isIdAvailable) {
      _showError('아이디 중복 확인을 해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = SignupData(
        id: _idController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        birth: _birthController.text.trim().isEmpty ? null : _birthController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
      );

      final result = await _apiService.signup(_idController.text.trim(), data);

      if (result['success'] == true) {
        if (!mounted) return;
        _showSuccess('회원가입이 완료되었습니다.');
        Navigator.pop(context);
      } else {
        _showError(result['message'] ?? '회원가입에 실패했습니다.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '회원가입',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 아이디 입력 + 중복확인
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _idController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration('아이디 *'),
                        onChanged: (_) {
                          setState(() {
                            _isIdChecked = false;
                            _isIdAvailable = false;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '아이디를 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkId,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isIdAvailable
                              ? AppColors.success
                              : AppColors.buttonPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                          ),
                        ),
                        child: Text(_isIdAvailable ? '확인완료' : '중복확인'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('비밀번호 *').copyWith(
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
                    if (value.length < 4) {
                      return '비밀번호는 4자 이상이어야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 확인
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('비밀번호 확인 *').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이름 입력
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('이름 *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이메일 입력 (선택)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('이메일 (선택)'),
                ),
                const SizedBox(height: 16),

                // 생년월일 입력 (선택)
                TextFormField(
                  controller: _birthController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('생년월일 (선택) - 예: 19900101'),
                ),
                const SizedBox(height: 16),

                // 회사명 입력 (선택 - 관리자 등록용)
                TextFormField(
                  controller: _companyController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('회사명 (관리자 등록시 필수)'),
                ),
                const SizedBox(height: 8),
                const Text(
                  '* 회사명을 입력하면 관리자(ADMIN)로 등록됩니다.',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: AppDimens.fontSmall,
                  ),
                ),
                const SizedBox(height: 32),

                // 회원가입 버튼
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
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
                            '회원가입',
                            style: TextStyle(
                              fontSize: AppDimens.fontLarge,
                              fontWeight: FontWeight.bold,
                            ),
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
