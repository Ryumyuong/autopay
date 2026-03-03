import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final notifications = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림을 불러오는 데 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> item) {
    final deepLink = item['deepLink'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      try {
        launchUrl(Uri.parse(deepLink));
      } catch (e) {
        debugPrint('Failed to open deep link: $e');
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
        title: const Text('알림', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          '알림이 없습니다',
                          style: TextStyle(color: AppColors.textHint, fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.divider,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final title = item['title'] as String? ?? '';
                      final body = item['body'] as String? ?? '';
                      final createdAt = item['createdAt'] as String? ?? '';
                      final hasDeepLink = (item['deepLink'] as String?)?.isNotEmpty == true;

                      return ListTile(
                        leading: const Icon(
                          Icons.notifications,
                          color: AppColors.buttonPrimary,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              body,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              createdAt,
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: hasDeepLink
                            ? const Icon(Icons.chevron_right, color: AppColors.textHint)
                            : null,
                        onTap: () => _handleNotificationTap(item),
                      );
                    },
                  ),
      ),
    );
  }
}
