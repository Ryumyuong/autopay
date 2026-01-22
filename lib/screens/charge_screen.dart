import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
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

  static const int _step1M = 1000000;
  static const int _maxAmount = 9999999999;

  void _addAmount(int million) {
    final addedAmount = million * _step1M;
    final newAmount = _currentAmount + addedAmount;
    if (newAmount <= _maxAmount) {
      setState(() => _currentAmount = newAmount);
    }
  }

  void _deleteLastDigit() {
    final millionCount = _currentAmount ~/ _step1M;
    final millionCountStr = millionCount.toString();
    if (millionCountStr.length > 1) {
      final newCount = int.parse(millionCountStr.substring(0, millionCountStr.length - 1));
      setState(() => _currentAmount = newCount * _step1M);
    } else {
      setState(() => _currentAmount = 0);
    }
  }

  void _clearAmount() {
    setState(() => _currentAmount = 0);
  }

  void _add00() {
    final millionCount = _currentAmount ~/ _step1M;
    final nextCountStr = '${millionCount}00';
    if (nextCountStr.length <= 4) {
      final nextCount = int.tryParse(nextCountStr) ?? 0;
      final newAmount = nextCount * _step1M;
      if (newAmount <= _maxAmount) {
        setState(() => _currentAmount = newAmount);
      }
    }
  }

  Future<void> _requestCharge() async {
    if (_currentAmount <= 0) {
      _showError('충전할 금액을 입력해주세요.');
      return;
    }

    if (_currentAmount % _step1M != 0) {
      _showError('100만원 단위로만 충전 가능합니다.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('충전 신청 확인', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${Formatters.formatPoint(_currentAmount)}\n충전을 신청하시겠습니까?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('신청', style: TextStyle(color: AppColors.charge)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final request = ChargeReqDTO(
        amount: _currentAmount,
        autopayId: widget.userName,
      );
      await _apiService.requestCharge(request);

      if (!mounted) return;
      _showSuccess('충전 신청이 완료되었습니다.');
      Navigator.pop(context);
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
          '충전 신청',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // 현재 포인트 표시
          Container(
            margin: const EdgeInsets.all(AppDimens.paddingMedium),
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '현재 보유 포인트',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  Formatters.formatPoint(widget.currentPoints),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 금액 표시
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '충전 금액',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppDimens.fontMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAmount > 0 ? Formatters.formatPoint(_currentAmount) : '0 p',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 숫자 키패드
          _buildKeypad(),

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
                            ? '${Formatters.formatPoint(_currentAmount)} 충전 신청'
                            : '충전할 금액을 설정하세요',
                        style: const TextStyle(fontSize: AppDimens.fontLarge, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Column(
        children: [
          Row(
            children: [
              _buildKeypadButton('1', () => _addAmount(1)),
              _buildKeypadButton('2', () => _addAmount(2)),
              _buildKeypadButton('3', () => _addAmount(3)),
            ],
          ),
          Row(
            children: [
              _buildKeypadButton('4', () => _addAmount(4)),
              _buildKeypadButton('5', () => _addAmount(5)),
              _buildKeypadButton('6', () => _addAmount(6)),
            ],
          ),
          Row(
            children: [
              _buildKeypadButton('7', () => _addAmount(7)),
              _buildKeypadButton('8', () => _addAmount(8)),
              _buildKeypadButton('9', () => _addAmount(9)),
            ],
          ),
          Row(
            children: [
              _buildKeypadButton('00', _add00),
              _buildKeypadButton('0', null, enabled: false),
              _buildKeypadButton('⌫', _deleteLastDigit, onLongPress: _clearAmount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label, VoidCallback? onPressed, {VoidCallback? onLongPress, bool enabled = true}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            child: Container(
              height: 64,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? AppColors.textPrimary : AppColors.textHint,
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
