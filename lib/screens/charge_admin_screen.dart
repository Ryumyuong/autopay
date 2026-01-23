import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'main_admin_screen.dart';

class ChargeAdminScreen extends StatefulWidget {
  const ChargeAdminScreen({super.key});

  @override
  State<ChargeAdminScreen> createState() => _ChargeAdminScreenState();
}

class _ChargeAdminScreenState extends State<ChargeAdminScreen> {
  final _apiService = ApiService();
  final _nameController = TextEditingController();
  int _currentAmount = 0;
  bool _isLoading = false;

  static const int _maxAmount = 9999999999;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addNumber(String number) {
    final currentValue = _currentAmount.toString();
    final newText = currentValue == '0' ? number : currentValue + number;

    if (newText.length <= 10) {
      final amount = int.tryParse(newText) ?? 0;
      if (amount <= _maxAmount) {
        setState(() => _currentAmount = amount);
      }
    }
  }

  void _deleteLastNumber() {
    final currentValue = _currentAmount.toString();
    if (currentValue.isNotEmpty && currentValue != '0') {
      final newText = currentValue.substring(0, currentValue.length - 1);
      setState(() => _currentAmount = newText.isEmpty ? 0 : int.parse(newText));
    }
  }

  void _clearAmount() {
    setState(() => _currentAmount = 0);
  }

  void _addFixedAmount(int amount) {
    final newAmount = _currentAmount + amount;
    if (newAmount <= _maxAmount) {
      setState(() => _currentAmount = newAmount);
    }
  }

  Future<void> _processPayment() async {
    final targetName = _nameController.text.trim();

    if (targetName.isEmpty) {
      _showError('이름을 입력해주세요.');
      return;
    }

    if (_currentAmount <= 0) {
      _showError('충전 금액을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 이름으로 사용자 검색
      final users = await _apiService.searchUsers(targetName);
      if (!mounted) return;

      // USER만 필터링 (ADMIN 제외, 탈퇴 유저 제외)
      final validUsers = users.where((user) =>
        user.name == targetName &&
        user.withdrawn != true &&
        user.rate != 'ADMIN'
      ).toList();

      if (validUsers.isEmpty) {
        _showError('해당 이름의 일반 사용자를 찾을 수 없습니다.');
        return;
      }

      // 찾은 사용자에게 충전
      if (validUsers.length > 1) {
        _showError('동명이인이 ${validUsers.length}명 있습니다. 첫 번째 사용자에게 충전합니다.');
      }

      await _showChargeConfirmDialog(validUsers.first, _currentAmount);
    } catch (e) {
      if (mounted) {
        _showError('네트워크 오류: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showChargeConfirmDialog(Person user, int amount) async {
    final userName = user.name ?? '알 수 없음';
    final message = '충전 대상: $userName\n현재 포인트: ${Formatters.formatPoint(user.point ?? 0)}\n충전 금액: ${Formatters.formatPoint(amount)}\n\n충전을 진행하시겠습니까?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('충전 확인', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('충전', style: TextStyle(color: AppColors.charge)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _completePayment(user, amount);
    }
  }

  Future<void> _completePayment(Person user, int amount) async {
    final userId = user.id;
    final userName = user.name;

    if (userId == null || userId.isEmpty) {
      _showError('사용자 ID를 찾을 수 없습니다.');
      return;
    }

    if (userName == null || userName.isEmpty) {
      _showError('사용자 이름을 찾을 수 없습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentPoints = user.point ?? 0;
      final newPoints = currentPoints + amount;

      final updatedPerson = Person(
        id: userId,
        name: userName,
        point: newPoints,
        rate: user.rate ?? 'USER',
        company: user.company,
      );

      await _apiService.updatePerson(userId, updatedPerson);
      if (!mounted) return;

      // 이력 기록
      final history = History(
        id: userId,
        name: userName,
        payment: amount,
        time: '',
        type: 'CHARGE',
        company: user.company,
        chargeName: '관리자',
      );

      await _apiService.postHistory(userId, history);
      if (!mounted) return;

      _showSuccess('${userName}님에게 ${Formatters.formatPoint(amount)} 충전 완료!');

      // 메인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainAdminScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _showError('충전 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  String get _buttonText {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '이름을 입력해주세요';
    if (_currentAmount <= 0) return '충전할 금액을 입력해주세요';
    return '${Formatters.formatPoint(_currentAmount)} 충전하기';
  }

  bool get _isButtonEnabled {
    return _nameController.text.trim().isNotEmpty && _currentAmount > 0;
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
          '관리자 충전',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 이름 입력 영역
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingLarge),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: '충전 대상 이름',
                labelStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // 금액 입력 영역
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge),
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentAmount > 0 ? Formatters.formatPoint(_currentAmount) : '금액을 입력하세요',
                    style: TextStyle(
                      color: _currentAmount > 0 ? AppColors.textPrimary : AppColors.textHint,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.textHint, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 고정 금액 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge),
            child: Row(
              children: [
                _buildFixedAmountButton('+1만', 10000),
                const SizedBox(width: 8),
                _buildFixedAmountButton('+5만', 50000),
                const SizedBox(width: 8),
                _buildFixedAmountButton('+10만', 100000),
                const SizedBox(width: 8),
                _buildFixedAmountButton('+100만', 1000000),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 숫자 키패드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge),
              child: _buildKeypad(),
            ),
          ),

          // 충전 버튼
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isButtonEnabled) ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.charge,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.buttonDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                        _buttonText,
                        style: const TextStyle(fontSize: AppDimens.fontLarge, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildFixedAmountButton(String label, int amount) {
    return Expanded(
      child: Material(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: InkWell(
          onTap: () => _addFixedAmount(amount),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          children: [
            _buildKeypadButton('1', () => _addNumber('1')),
            _buildKeypadButton('2', () => _addNumber('2')),
            _buildKeypadButton('3', () => _addNumber('3')),
          ],
        ),
        Row(
          children: [
            _buildKeypadButton('4', () => _addNumber('4')),
            _buildKeypadButton('5', () => _addNumber('5')),
            _buildKeypadButton('6', () => _addNumber('6')),
          ],
        ),
        Row(
          children: [
            _buildKeypadButton('7', () => _addNumber('7')),
            _buildKeypadButton('8', () => _addNumber('8')),
            _buildKeypadButton('9', () => _addNumber('9')),
          ],
        ),
        Row(
          children: [
            _buildKeypadButton('00', () => _addNumber('00')),
            _buildKeypadButton('0', () => _addNumber('0')),
            _buildKeypadButton('⌫', _deleteLastNumber, onLongPress: _clearAmount),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String label, VoidCallback? onPressed, {VoidCallback? onLongPress}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: InkWell(
            onTap: onPressed,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
