import 'package:flutter/material.dart';
import '../utils/constants.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _flashOn = false;

  // QR 코드 스캔 결과 처리
  void _onQrScanned(String data) {
    // QR 코드 데이터 처리 로직
    debugPrint('QR Scanned: $data');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('QR 코드 스캔', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '스캔된 데이터:\n$data',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: AppColors.buttonPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('QR 코드 스캔', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _flashOn = !_flashOn);
              // TODO: 실제 플래시 제어 로직
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR 스캐너 뷰 (실제 구현 시 qr_code_scanner 패키지 사용)
          // QRView(
          //   key: qrKey,
          //   onQRViewCreated: _onQRViewCreated,
          // ),

          // 임시 플레이스홀더
          Container(
            color: Colors.black87,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 100, color: Colors.white54),
                  SizedBox(height: 24),
                  Text(
                    'QR 코드 스캐너',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '카메라 권한이 필요합니다',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // 스캔 프레임 오버레이
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.buttonPrimary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // 코너 장식
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCorner(true, true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCorner(true, false),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCorner(false, true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCorner(false, false),
                  ),
                ],
              ),
            ),
          ),

          // 안내 텍스트
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'QR 코드를 프레임 안에 맞춰주세요',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 수동 입력 버튼
                TextButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard, color: AppColors.buttonPrimary),
                  label: const Text(
                    'ID 직접 입력',
                    style: TextStyle(color: AppColors.buttonPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.buttonPrimary, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.buttonPrimary, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.buttonPrimary, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.buttonPrimary, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('ID 직접 입력', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '결제 대상 ID 입력',
            hintStyle: const TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final id = controller.text.trim();
              if (id.isNotEmpty) {
                Navigator.pop(context);
                _onQrScanned(id);
              }
            },
            child: const Text('확인', style: TextStyle(color: AppColors.buttonPrimary)),
          ),
        ],
      ),
    );
  }
}
