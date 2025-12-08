import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class RechargeScreen extends StatefulWidget {
  final String userName;
  final int currentPoints;

  const RechargeScreen({
    super.key,
    required this.userName,
    required this.currentPoints,
  });

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _apiService = ApiService();
  int _currentAmount = 0;
  bool _isLoading = false;

  static const int _step1M = 1000000;
  static const int _maxAmount = 9999999999;
  static const String _adminId = 'admin';

  void _addAmount(int million) {
    final addedAmount = million * _step1M;
    final newAmount = _currentAmount + addedAmount;
    if (newAmount <= _maxAmount && newAmount <= widget.currentPoints) {
      setState(() => _currentAmount = newAmount);
    } else if (newAmount > widget.currentPoints) {
      _showError('포인트가 부족합니다.');
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
      if (newAmount <= _maxAmount && newAmount <= widget.currentPoints) {
        setState(() => _currentAmount = newAmount);
      } else if (newAmount > widget.currentPoints) {
        _showError('포인트가 부족합니다.');
      }
    }
  }

  Future<void> _processSettlement() async {
    if (_currentAmount <= 0) {
      _showError('정산할 금액을 입력해주세요.');
      return;
    }

    if (_currentAmount % _step1M != 0) {
      _showError('100만원 단위로만 정산 가능합니다.');
      return;
    }

    if (_currentAmount > widget.currentPoints) {
      _showError('포인트가 부족합니다.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('포인트 정산 확인', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '금액: ${Formatters.formatPoint(_currentAmount)}\n포인트를 정산 신청하시겠습니까?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('정산', style: TextStyle(color: AppColors.payment)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // 1. 내 정보 조회
      final me = await _apiService.getPerson(widget.userName);
      final currentPoints = me.point ?? 0;

      if (currentPoints < _currentAmount) {
        _showError('포인트가 부족합니다. (보유: ${Formatters.formatPoint(currentPoints)})');
        return;
      }

      // 2. 포인트 차감
      final newPoints = currentPoints - _currentAmount;
      final updatedPerson = Person(
        id: me.id,
        name: me.name,
        point: newPoints,
        rate: me.rate,
        company: me.company,
      );
      await _apiService.updatePerson(widget.userName, updatedPerson);

      // 3. 거래 내역 저장
      final history = History(
        id: widget.userName,
        name: me.name,
        payment: _currentAmount,
        type: 'PAYMENT',
        company: me.company,
        chargeName: '오토페이',
      );
      await _apiService.postHistory(widget.userName, history);

      // 4. 정산 알림 발송
      final pushReq = PaymentPushReq(
        payerId: widget.userName,
        payerName: me.name,
        payeeId: _adminId,
        payeeName: '오토페이',
        amount: _currentAmount,
      );
      await _apiService.notifySettlement(pushReq);

      if (!mounted) return;
      _showSuccess('정산이 완료되었습니다!');
      Navigator.pop(context);
    } catch (e) {
      _showError('정산 처리 중 오류가 발생했습니다: $e');
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
        title: const Text('정산하기', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          // 현재 포인트 표시
          Container(
            margin: const EdgeInsets.all(AppDimens.paddingMedium),
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('보유 포인트', style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  Formatters.formatPoint(widget.currentPoints),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 안내 문구
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.payment.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(color: AppColors.payment.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.payment, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '정산 신청 시 보유 포인트가 차감되며, 관리자 확인 후 현금으로 정산됩니다.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                    '정산 금액',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimens.fontMedium),
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

          // 정산 버튼
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || _currentAmount <= 0) ? null : _processSettlement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.payment,
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
                            ? '${Formatters.formatPoint(_currentAmount)} 정산하기'
                            : '정산할 금액을 설정하세요',
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
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? AppColors.textPrimary : AppColors.textHint,
                  fontSize: 22,
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
