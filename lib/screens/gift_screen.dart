import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'main_screen.dart';

class GiftScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int currentPoints;

  const GiftScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.currentPoints,
  });

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  late String _myUserId;
  late String _myUserName;
  late int _myPoints;

  Person? _selectedUser;
  List<Person> _searchResults = [];
  int _currentAmount = 0;
  bool _isLoading = false;
  bool _isSearching = false;

  static const int _maxAmount = 9999999999;

  @override
  void initState() {
    super.initState();
    _myUserId = widget.userId;
    _myUserName = widget.userName;
    _myPoints = widget.currentPoints;
    _refreshPoints();
  }

  Future<void> _refreshPoints() async {
    if (_myUserId.isNotEmpty) {
      try {
        final person = await _apiService.getPerson(_myUserId);
        setState(() => _myPoints = person.point ?? 0);
      } catch (e) {
        debugPrint('Error loading user info: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final searchName = _searchController.text.trim();
    if (searchName.isEmpty) {
      _showError('이름을 입력해주세요');
      return;
    }

    setState(() => _isSearching = true);

    try {
      final users = await _apiService.searchUsers(searchName);

      // 자기 자신 제외, 탈퇴 유저 제외, USER만 포함
      final filteredUsers = users.where((user) =>
        user.id != _myUserId &&
        user.withdrawn != true &&
        user.rate == 'USER'
      ).toList();

      setState(() {
        _searchResults = filteredUsers;
      });

      if (filteredUsers.isEmpty) {
        _showError('검색 결과가 없습니다');
      }
    } catch (e) {
      _showError('검색 실패: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectUser(Person user) {
    setState(() {
      _selectedUser = user;
      _searchResults = [];
    });
  }

  void _resetToSearchMode() {
    setState(() {
      _selectedUser = null;
      _currentAmount = 0;
      _searchResults = [];
      _searchController.clear();
    });
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

  Future<void> _processGift() async {
    if (_selectedUser == null) {
      _showError('받는 분을 선택해주세요');
      return;
    }

    if (_currentAmount <= 0) {
      _showError('선물할 금액을 입력해주세요');
      return;
    }

    if (_currentAmount > _myPoints) {
      _showError('보유 포인트가 부족합니다');
      return;
    }

    final receiver = _selectedUser!;
    final message = '받는 분: ${receiver.name}\n선물 금액: ${Formatters.formatPoint(_currentAmount)}\n\n선물을 보내시겠습니까?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('선물 확인', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('보내기', style: TextStyle(color: AppColors.charge)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _executeGift(receiver, _currentAmount);
  }

  Future<void> _executeGift(Person receiver, int amount) async {
    setState(() => _isLoading = true);

    try {
      final receiverId = receiver.id ?? '';

      // Step 1: 내 포인트 차감
      final myNewPoint = _myPoints - amount;
      final myUpdatedPerson = Person(
        id: _myUserId,
        name: _myUserName,
        point: myNewPoint,
      );
      await _apiService.updatePerson(_myUserId, myUpdatedPerson);

      // Step 2: 내 이력 저장 (GIFT_SEND)
      final senderHistory = History(
        id: _myUserId,
        name: _myUserName,
        payment: -amount,
        time: '',
        type: 'GIFT_SEND',
        chargeName: receiver.name,
      );
      await _apiService.postHistory(_myUserId, senderHistory);

      // Step 3: 상대 포인트 증가
      final receiverNewPoint = (receiver.point ?? 0) + amount;
      final receiverUpdatedPerson = Person(
        id: receiverId,
        name: receiver.name,
        point: receiverNewPoint,
      );
      await _apiService.updatePerson(receiverId, receiverUpdatedPerson);

      // Step 4: 상대 이력 저장 (GIFT_RECEIVE)
      final receiverHistory = History(
        id: receiverId,
        name: receiver.name,
        payment: amount,
        time: '',
        type: 'GIFT_RECEIVE',
        chargeName: _myUserName,
      );
      await _apiService.postHistory(receiverId, receiverHistory);

      // Step 5: 푸시 알림
      try {
        await _apiService.notifyGift(GiftPushReq(
          senderId: _myUserId,
          senderName: _myUserName,
          receiverId: receiverId,
          receiverName: receiver.name,
          amount: amount,
        ));
      } catch (e) {
        debugPrint('Push notification failed: $e');
      }

      if (!mounted) return;
      _showSuccess('선물이 완료되었습니다!');

      // 메인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError('선물 실패: $e');
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

  String get _buttonText {
    if (_selectedUser == null) return '받는 분을 선택해주세요';
    if (_currentAmount <= 0) return '선물할 금액을 입력해주세요';
    if (_currentAmount > _myPoints) return '포인트가 부족합니다';
    return '${Formatters.formatPoint(_currentAmount)} 선물하기';
  }

  bool get _isButtonEnabled {
    return _selectedUser != null && _currentAmount > 0 && _currentAmount <= _myPoints;
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
          onPressed: () {
            if (_selectedUser != null) {
              _resetToSearchMode();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          '포인트 선물',
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
                '나의 포인트: ${Formatters.formatPoint(_myPoints)}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ),

          if (_selectedUser == null) ...[
            // 검색 영역
            _buildSearchSection(),
          ] else ...[
            // 금액 입력 영역
            _buildAmountSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge),
        child: Column(
          children: [
            // 검색 입력
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '받는 분 이름 검색',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('검색', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 검색 결과
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        '이름을 검색해주세요',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryDark,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            user.name ?? '이름 없음',
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            user.id ?? '',
                            style: const TextStyle(color: AppColors.textHint),
                          ),
                          onTap: () => _selectUser(user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Expanded(
      child: Column(
        children: [
          // 선택된 사용자 표시
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge),
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_selectedUser?.name ?? ""}님에게 선물',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _resetToSearchMode,
                  child: const Text('변경', style: TextStyle(color: AppColors.pointGold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
              ],
            ),
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),

          // 숫자 키패드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge),
              child: _buildKeypad(),
            ),
          ),

          // 선물 버튼
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isButtonEnabled) ? null : _processGift,
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
