import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class PaymentScreen extends StatefulWidget {
  final String userName;
  final String userDisplayName;
  final int currentPoints;

  const PaymentScreen({
    super.key,
    required this.userName,
    required this.userDisplayName,
    required this.currentPoints,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _apiService = ApiService();
  final _payeeIdController = TextEditingController();

  int _currentAmount = 0;
  bool _isLoading = false;
  Person? _payee;
  bool _isPayeeValid = false;

  static const int _step1M = 1000000;
  static const int _maxAmount = 9999999999;

  @override
  void dispose() {
    _payeeIdController.dispose();
    super.dispose();
  }

  Future<void> _searchPayee() async {
    final payeeId = _payeeIdController.text.trim();
    if (payeeId.isEmpty) {
      _showError('결제 대상 ID를 입력해주세요.');
      return;
    }

    if (payeeId == widget.userName) {
      _showError('본인에게는 결제할 수 없습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _payee = await _apiService.getPerson(payeeId);
      setState(() => _isPayeeValid = true);
      _showSuccess('${_payee?.name ?? payeeId}님을 찾았습니다.');
    } catch (e) {
      setState(() {
        _payee = null;
        _isPayeeValid = false;
      });
      _showError('사용자를 찾을 수 없습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  Future<void> _processPayment() async {
    final payee = _payee;
    if (!_isPayeeValid || payee == null) {
      _showError('결제 대상을 먼저 검색해주세요.');
      return;
    }

    final payeeId = payee.id;
    if (payeeId == null || payeeId.isEmpty) {
      _showError('결제 대상 ID를 찾을 수 없습니다.');
      return;
    }

    if (_currentAmount <= 0) {
      _showError('결제 금액을 입력해주세요.');
      return;
    }

    if (_currentAmount > widget.currentPoints) {
      _showError('포인트가 부족합니다.');
      return;
    }

    final payeeName = payee.isAdmin
        ? (payee.company ?? payee.name ?? 'Unknown')
        : (payee.name ?? 'Unknown');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('결제 확인', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '받는 분: $payeeName\n금액: ${Formatters.formatPoint(_currentAmount)}\n\n결제하시겠습니까?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('결제', style: TextStyle(color: AppColors.buttonPrimary)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      // 1. 내 포인트 차감
      final myNewPoints = widget.currentPoints - _currentAmount;
      final myPerson = Person(
        id: widget.userName,
        name: widget.userDisplayName,
        point: myNewPoints,
      );
      await _apiService.updatePerson(widget.userName, myPerson);
      if (!mounted) return;

      // 2. 상대방 포인트 증가
      final payeeNewPoints = (payee.point ?? 0) + _currentAmount;
      final payeePerson = Person(
        id: payeeId,
        name: payee.name,
        point: payeeNewPoints,
      );
      await _apiService.updatePerson(payeeId, payeePerson);
      if (!mounted) return;

      // 3. 내 거래 내역 저장 (PAYMENT)
      final myHistory = History(
        id: widget.userName,
        name: widget.userDisplayName,
        payment: _currentAmount,
        type: 'PAYMENT',
        company: payee.company,
        chargeName: payeeName,
      );
      await _apiService.postHistory(widget.userName, myHistory);
      if (!mounted) return;

      // 4. 상대방 거래 내역 저장 (CHARGE)
      final payeeHistory = History(
        id: payeeId,
        name: payee.name,
        payment: _currentAmount,
        type: 'CHARGE',
        company: null,
        chargeName: widget.userDisplayName,
      );
      await _apiService.postHistory(payeeId, payeeHistory);
      if (!mounted) return;

      // 5. 결제 알림 발송
      try {
        final pushReq = PaymentPushReq(
          payerId: widget.userName,
          payerName: widget.userDisplayName,
          payeeId: payeeId,
          payeeName: payeeName,
          amount: _currentAmount,
        );
        await _apiService.notifyPayment(pushReq);
      } catch (e) {
        // 푸시 알림 실패해도 결제는 성공으로 처리
        debugPrint('Push notification failed: $e');
      }

      if (!mounted) return;
      _showSuccess('결제가 완료되었습니다.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showError('결제 처리 중 오류가 발생했습니다: $e');
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
        title: const Text('결제하기', style: TextStyle(color: AppColors.textPrimary)),
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
                const Text('보유 포인트', style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  Formatters.formatPoint(widget.currentPoints),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 결제 대상 검색
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _payeeIdController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: '결제 대상 ID 입력',
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
                      suffixIcon: _isPayeeValid
                          ? const Icon(Icons.check_circle, color: AppColors.success)
                          : null,
                    ),
                    onChanged: (_) {
                      setState(() {
                        _isPayeeValid = false;
                        _payee = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchPayee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    ),
                  ),
                  child: const Text('검색'),
                ),
              ],
            ),
          ),

          // 결제 대상 정보
          if (_isPayeeValid && _payee != null)
            Container(
              margin: const EdgeInsets.all(AppDimens.paddingMedium),
              padding: const EdgeInsets.all(AppDimens.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.charge.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(color: AppColors.charge.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.charge),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _payee!.isAdmin ? (_payee!.company ?? _payee!.name ?? '') : (_payee!.name ?? ''),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _payee!.id ?? '',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_payee!.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                    '결제 금액',
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

          // 결제 버튼
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || _currentAmount <= 0 || !_isPayeeValid) ? null : _processPayment,
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
                    : Text(
                        _currentAmount > 0 && _isPayeeValid
                            ? '${Formatters.formatPoint(_currentAmount)} 결제하기'
                            : '결제할 금액을 설정하세요',
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
