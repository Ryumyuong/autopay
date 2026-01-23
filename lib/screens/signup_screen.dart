import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

enum MemberType { normal, company }

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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthController = TextEditingController();
  final _companyController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _isIdChecking = false;
  bool _isIdValid = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  MemberType? _memberType;

  // 실시간 검증 상태
  String? _idError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _birthError;
  String? _companyError;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  // 아이디 검증 (Android와 동일)
  Future<void> _validateId(String id) async {
    if (id.length < 4) {
      setState(() {
        _idError = '아이디는 4자 이상이어야 합니다';
        _isIdValid = false;
      });
      return;
    }
    if (id.length > 20) {
      setState(() {
        _idError = '아이디는 20자 이하여야 합니다';
        _isIdValid = false;
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(id)) {
      setState(() {
        _idError = '영어, 숫자만 가능합니다';
        _isIdValid = false;
      });
      return;
    }

    setState(() => _isIdChecking = true);

    try {
      final exists = await _apiService.checkIdExists(id);
      if (exists) {
        setState(() {
          _idError = '이미 사용 중인 아이디입니다';
          _isIdValid = false;
        });
      } else {
        setState(() {
          _idError = null;
          _isIdValid = true;
        });
      }
    } catch (e) {
      setState(() {
        _idError = '네트워크 오류로 확인 실패';
        _isIdValid = false;
      });
    } finally {
      setState(() => _isIdChecking = false);
    }
  }

  // 비밀번호 검증 (Android와 동일)
  void _validatePassword(String password) {
    if (password.length < 8) {
      setState(() => _passwordError = '비밀번호는 8자 이상이어야 합니다');
      return;
    }
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$').hasMatch(password)) {
      setState(() => _passwordError = '영어, 숫자, 특수문자를 포함해야 합니다');
      return;
    }
    setState(() => _passwordError = null);
    // 비밀번호 확인도 다시 검사
    _validatePasswordConfirm(_confirmPasswordController.text);
  }

  // 비밀번호 확인 검증
  void _validatePasswordConfirm(String confirm) {
    if (confirm != _passwordController.text) {
      setState(() => _confirmPasswordError = '비밀번호가 일치하지 않습니다');
    } else {
      setState(() => _confirmPasswordError = null);
    }
  }

  // 이름 검증
  void _validateName(String name) {
    if (name.length < 2) {
      setState(() => _nameError = '이름은 2자 이상이어야 합니다');
      return;
    }
    if (name.length > 10) {
      setState(() => _nameError = '이름은 10자 이하여야 합니다');
      return;
    }
    if (!RegExp(r'^[가-힣a-zA-Z]+$').hasMatch(name)) {
      setState(() => _nameError = '한글 또는 영어만 입력 가능합니다');
      return;
    }
    setState(() => _nameError = null);
  }

  // 전화번호 검증
  void _validatePhone(String phone) {
    if (phone.isEmpty) {
      setState(() => _phoneError = '전화번호를 입력해주세요');
      return;
    }
    if (!RegExp(r'^[0-9-]+$').hasMatch(phone)) {
      setState(() => _phoneError = '올바른 전화번호 형식이 아닙니다');
      return;
    }
    setState(() => _phoneError = null);
  }

  // 이메일 검증
  void _validateEmail(String email) {
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = '올바른 이메일 형식이 아닙니다');
    } else {
      setState(() => _emailError = null);
    }
  }

  // 생년월일 검증
  void _validateBirth(String birth) {
    if (birth.length != 8) {
      setState(() => _birthError = '생년월일 8자리를 입력해주세요 (예: 19900101)');
      return;
    }
    if (!RegExp(r'^\d{8}$').hasMatch(birth)) {
      setState(() => _birthError = '숫자만 입력해주세요');
      return;
    }
    // 날짜 유효성 검사
    try {
      final year = int.parse(birth.substring(0, 4));
      final month = int.parse(birth.substring(4, 6));
      final day = int.parse(birth.substring(6, 8));
      final currentYear = DateTime.now().year;

      if (year < 1900 || year > currentYear || month < 1 || month > 12 || day < 1 || day > 31) {
        setState(() => _birthError = '올바른 날짜를 입력해주세요');
        return;
      }
    } catch (e) {
      setState(() => _birthError = '올바른 날짜를 입력해주세요');
      return;
    }
    setState(() => _birthError = null);
  }

  // 업체명 검증
  void _validateCompany(String company) {
    if (_memberType == MemberType.company && company.isEmpty) {
      setState(() => _companyError = '업체명을 입력해주세요');
    } else {
      setState(() => _companyError = null);
    }
  }

  bool _validateAllFields() {
    if (_memberType == null) {
      _showError('일반/사업자 중 하나를 선택해주세요');
      return false;
    }

    if (!_isIdValid) {
      _showError('아이디를 확인해주세요');
      return false;
    }

    if (_passwordError != null || _confirmPasswordError != null) {
      _showError('비밀번호를 확인해주세요');
      return false;
    }

    if (_nameError != null) {
      _showError('이름을 확인해주세요');
      return false;
    }

    if (_phoneError != null) {
      _showError('전화번호를 확인해주세요');
      return false;
    }

    if (_emailError != null) {
      _showError('이메일을 확인해주세요');
      return false;
    }

    if (_birthError != null) {
      _showError('생년월일을 확인해주세요');
      return false;
    }

    if (_memberType == MemberType.company && _companyController.text.isEmpty) {
      _showError('업체명을 입력해주세요');
      return false;
    }

    return true;
  }

  Future<void> _signup() async {
    if (!_validateAllFields()) return;

    setState(() => _isLoading = true);

    try {
      final data = SignupData(
        id: _idController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        birth: _birthController.text.trim(),
        company: _memberType == MemberType.company ? _companyController.text.trim() : null,
      );

      final result = await _apiService.signup(_idController.text.trim(), data);

      if (result['success'] == true || result['id'] != null) {
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
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  bool get _isFormEnabled => _memberType != null;

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
        title: const Text('회원가입', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 일반/사업자 선택 (Android와 동일)
                Row(
                  children: [
                    Expanded(
                      child: _buildMemberTypeButton(
                        '일반',
                        MemberType.normal,
                        _memberType == MemberType.normal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMemberTypeButton(
                        '사업자',
                        MemberType.company,
                        _memberType == MemberType.company,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 아이디 입력
                _buildTextField(
                  controller: _idController,
                  label: '아이디 *',
                  enabled: _isFormEnabled,
                  errorText: _idError,
                  suffixIcon: _isIdChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isIdValid
                          ? const Icon(Icons.check_circle, color: AppColors.success)
                          : null,
                  onChanged: (v) => _validateId(v),
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력
                _buildTextField(
                  controller: _passwordController,
                  label: '비밀번호 *',
                  obscureText: _obscurePassword,
                  enabled: _isFormEnabled,
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  onChanged: _validatePassword,
                ),
                const SizedBox(height: 16),

                // 비밀번호 확인
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: '비밀번호 확인 *',
                  obscureText: _obscureConfirmPassword,
                  enabled: _isFormEnabled,
                  errorText: _confirmPasswordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  onChanged: _validatePasswordConfirm,
                ),
                const SizedBox(height: 16),

                // 이름 입력
                _buildTextField(
                  controller: _nameController,
                  label: '이름 *',
                  enabled: _isFormEnabled,
                  errorText: _nameError,
                  onChanged: _validateName,
                ),
                const SizedBox(height: 16),

                // 전화번호 입력 (Android와 동일하게 추가)
                _buildTextField(
                  controller: _phoneController,
                  label: '전화번호 *',
                  enabled: _isFormEnabled,
                  errorText: _phoneError,
                  keyboardType: TextInputType.phone,
                  onChanged: _validatePhone,
                ),
                const SizedBox(height: 16),

                // 이메일 입력
                _buildTextField(
                  controller: _emailController,
                  label: '이메일 *',
                  enabled: _isFormEnabled,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _validateEmail,
                ),
                const SizedBox(height: 16),

                // 생년월일 입력
                _buildTextField(
                  controller: _birthController,
                  label: '생년월일 * (예: 19900101)',
                  enabled: _isFormEnabled,
                  errorText: _birthError,
                  keyboardType: TextInputType.number,
                  onChanged: _validateBirth,
                ),
                const SizedBox(height: 16),

                // 업체명 입력 (사업자만)
                _buildTextField(
                  controller: _companyController,
                  label: '업체명 (사업자)',
                  enabled: _memberType == MemberType.company,
                  errorText: _companyError,
                  onChanged: _validateCompany,
                ),
                const SizedBox(height: 32),

                // 회원가입 버튼
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isFormEnabled) ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.buttonDisabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text(
                            '회원가입',
                            style: TextStyle(fontSize: AppDimens.fontLarge, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 로그인 화면으로 이동
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      '이미 회원이신가요? 로그인',
                      style: TextStyle(color: AppColors.accent, fontSize: 14),
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

  Widget _buildMemberTypeButton(String label, MemberType type, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _memberType = type;
          if (type == MemberType.normal) {
            _companyController.clear();
            _companyError = null;
          }
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.cardBorder,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: AppDimens.fontLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    bool obscureText = false,
    String? errorText,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled ? AppColors.textPrimary : AppColors.textHint,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textHint),
            suffixIcon: suffixIcon,
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: onChanged,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
