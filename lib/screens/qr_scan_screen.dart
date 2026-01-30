import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/constants.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController? _controller;
  bool _isScanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        _onQrScanned(barcode.rawValue!);
        break;
      }
    }
  }

  void _onQrScanned(String data) {
    debugPrint('QR Scanned: $data');

    // QR 데이터에서 user_id 추출
    final userId = _extractUserId(data);

    if (userId != null && userId.isNotEmpty) {
      // ID가 추출되면 바로 반환
      Navigator.pop(context, userId);
    } else {
      // ID가 없으면 에러 메시지 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.primaryDark,
          title: const Text('QR 코드 오류', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            'QR 코드에서 사용자 ID를 찾을 수 없습니다.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isScanned = false);
              },
              child: const Text('다시 스캔', style: TextStyle(color: AppColors.buttonPrimary)),
            ),
          ],
        ),
      );
    }
  }

  /// QR 데이터에서 user_id 추출
  /// 지원 형식:
  /// - autopay://payment?user_id=xxx
  /// - http://xxx/pay.html?user_id=xxx
  /// - id=xxx
  String? _extractUserId(String qrData) {
    try {
      final uri = Uri.parse(qrData);
      // user_id 파라미터 확인
      final userId = uri.queryParameters['user_id'] ?? uri.queryParameters['id'];
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
    } catch (e) {
      debugPrint('URI parsing failed: $e');
    }

    // 단순 key=value 형식 처리: id=xxx 또는 user_id=xxx
    if (qrData.contains('user_id=')) {
      return qrData.split('user_id=').last.split('&').first;
    }
    if (qrData.contains('id=')) {
      return qrData.split('id=').last.split('&').first;
    }

    return null;
  }

  void _toggleTorch() async {
    await _controller?.toggleTorch();
    setState(() => _torchOn = !_torchOn);
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
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller?.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR 스캐너 뷰
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
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
                  Positioned(top: 0, left: 0, child: _buildCorner(true, true)),
                  Positioned(top: 0, right: 0, child: _buildCorner(true, false)),
                  Positioned(bottom: 0, left: 0, child: _buildCorner(false, true)),
                  Positioned(bottom: 0, right: 0, child: _buildCorner(false, false)),
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
                Navigator.pop(context, id);
              }
            },
            child: const Text('확인', style: TextStyle(color: AppColors.buttonPrimary)),
          ),
        ],
      ),
    );
  }
}
