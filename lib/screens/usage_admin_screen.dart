import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class UsageAdminScreen extends StatefulWidget {
  const UsageAdminScreen({super.key});

  @override
  State<UsageAdminScreen> createState() => _UsageAdminScreenState();
}

class _UsageAdminScreenState extends State<UsageAdminScreen> {
  final _apiService = ApiService();
  List<History> _historyList = [];
  bool _isLoading = true;
  String _userId = '';

  // 요약 정보
  int _totalCharge = 0;
  int _totalPayment = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      _userId = await TokenStore.getUserId() ?? '';
      if (_userId.isNotEmpty) {
        _historyList = await _apiService.getHistory(_userId);
        _calculateSummary();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateSummary() {
    _totalCharge = 0;
    _totalPayment = 0;

    for (final history in _historyList) {
      if (history.isCharge) {
        _totalCharge += history.payment ?? 0;
      } else {
        _totalPayment += history.payment ?? 0;
      }
    }
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
        title: const Text('거래 내역', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
          : Column(
              children: [
                // 요약 카드
                _buildSummaryCard(),

                // 내역 리스트
                Expanded(
                  child: _historyList.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppDimens.paddingMedium),
                            itemCount: _historyList.length,
                            itemBuilder: (context, index) {
                              final history = _historyList[index];
                              return _buildHistoryItem(history);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(AppDimens.paddingMedium),
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text(
                  '총 충전',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimens.fontSmall),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${Formatters.formatCurrency(_totalCharge)}',
                  style: const TextStyle(
                    color: AppColors.charge,
                    fontWeight: FontWeight.bold,
                    fontSize: AppDimens.fontLarge,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.textHint.withOpacity(0.3),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  '총 결제/정산',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimens.fontSmall),
                ),
                const SizedBox(height: 4),
                Text(
                  '-${Formatters.formatCurrency(_totalPayment)}',
                  style: const TextStyle(
                    color: AppColors.payment,
                    fontWeight: FontWeight.bold,
                    fontSize: AppDimens.fontLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            '거래 내역이 없습니다.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimens.fontMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(History history) {
    final isCharge = history.isCharge;
    final color = isCharge ? AppColors.charge : AppColors.payment;
    final icon = isCharge ? Icons.add_circle : Icons.remove_circle;
    final prefix = isCharge ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      history.chargeName ?? (isCharge ? '충전' : '결제'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppDimens.fontMedium,
                      ),
                    ),
                    if (history.company != null && history.company!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          history.company!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatDateTime(history.time),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: AppDimens.fontSmall,
                  ),
                ),
              ],
            ),
          ),

          // 금액
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${Formatters.formatCurrency(history.payment)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimens.fontLarge,
                ),
              ),
              Text(
                isCharge ? '충전' : (history.type == 'PAYMENT' ? '결제' : '정산'),
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: AppDimens.fontSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
