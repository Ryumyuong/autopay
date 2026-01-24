import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  final _apiService = ApiService();
  List<History> _historyList = [];
  bool _isLoading = true;
  String _userId = '';

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
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: const Text('사용 내역', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
          : _historyList.isEmpty
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
            '사용 내역이 없습니다.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimens.fontMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(History history) {
    // 타입에 따른 색상, 아이콘, 부호 결정
    final bool isPositive = history.isCharge || history.isGiftReceive;
    final color = isPositive ? AppColors.charge : AppColors.payment;
    final icon = isPositive ? Icons.add_circle : Icons.remove_circle;
    final prefix = isPositive ? '+' : '-';

    // 타입에 따른 표시 이름 결정
    String displayName;
    String typeLabel;
    if (history.isGiftSend) {
      displayName = '선물 → ${history.chargeName ?? "알 수 없음"}';
      typeLabel = '선물';
    } else if (history.isGiftReceive) {
      displayName = '선물 ← ${history.chargeName ?? "알 수 없음"}';
      typeLabel = '선물';
    } else if (history.isCharge) {
      displayName = history.chargeName ?? '충전';
      typeLabel = '충전';
    } else {
      displayName = history.company ?? history.chargeName ?? '결제';
      typeLabel = '결제';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
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
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: AppDimens.fontMedium,
                  ),
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
                '$prefix${Formatters.formatCurrency((history.payment ?? 0).abs())}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimens.fontLarge,
                ),
              ),
              Text(
                typeLabel,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
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
