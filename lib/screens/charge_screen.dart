import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class ChargeScreen extends StatefulWidget {
  final String userName;
  final int currentPoints;

  const ChargeScreen({
    super.key,
    required this.userName,
    required this.currentPoints,
  });

  @override
  State<ChargeScreen> createState() => _ChargeScreenState();
}

class _ChargeScreenState extends State<ChargeScreen> {
  final _apiService = ApiService();
  int _currentAmount = 0;
  bool _isLoading = false;

  static const int _maxAmount = 9999999999;

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

  Future<void> _requestCharge() async {
    if (_currentAmount <= 0) {
      _showError('충전 금액을 입력해주세요.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('충전 신청 확인', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '금액: ${Formatters.formatPoint(_currentAmount)}\n충전 신청을 진행하시겠습니까?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('충전 신청', style: TextStyle(color: AppColors.charge)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final request = ChargeReqDTO(
        amount: _currentAmount,
        autopayId: widget.userName,
      );
      final response = await _apiService.requestCharge(request);
      if (!mounted) return;

      final ok = response['ok'] as bool? ?? false;
      if (ok) {
        // 로컬 알림 표시 (Android와 동일)
        await FirebaseService().notifyChargeComplete(_currentAmount);

        // 관리자에게 푸시 알림 전송
        try {
          await _apiService.notifyAdminForCharge(ChargePushReq(
            userId: widget.userName,
            amount: _currentAmount,
          ));
        } catch (e) {
          debugPrint('Push notification failed: $e');
        }

        if (!mounted) return;
        _showSuccess('충전 신청이 완료되었습니다.');
        Navigator.pop(context);
      } else {
        final message = response['message'] as String? ?? '충전 신청 실패';
        _showError(message);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
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
          '충전신청',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 현재 포인트 표시
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingLarge),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '나의 포인트: ${Formatters.formatPoint(widget.currentPoints)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
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

          // 고정 금액 버튼들 (Android와 동일)
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

          // 충전 신청 버튼
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || _currentAmount <= 0) ? null : _requestCharge,
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
                        _currentAmount > 0
                            ? '${Formatters.formatPoint(_currentAmount)} 충전하기'
                            : '충전할 금액을 입력해주세요',
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
