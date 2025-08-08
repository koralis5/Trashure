import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:get_it/get_it.dart';
import '../models/colours.dart';
import '../services/nets_qr_service.dart';
import '../services/notification_service.dart';

class QrPaymentScreen extends StatefulWidget {
  static const routeName = '/qr-payment';

  const QrPaymentScreen({super.key});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  final NetsQrService _netsService = NetsQrService();
  final NotificationService _notificationService = GetIt.instance<NotificationService>();

  String? qrCodeBase64;
  String? txnRetrievalRef;
  String? orderId;
  bool isLoading = true;
  bool isPaymentCompleted = false;
  bool isPaymentFailed = false;
  String statusMessage = '';

  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  StreamSubscription? _paymentStream;
  int remainingSeconds = 300; // 5 minutes

  Map<String, dynamic>? listing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePayment();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _paymentStream?.cancel();
    super.dispose();
  }

  void _initializePayment() {
    listing = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (listing != null) {
      orderId = 'TRX${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
      _generateQrCode();
    }
  }

  Future<void> _generateQrCode() async {
    if (listing == null) return;

    setState(() => isLoading = true);

    try {
      final title = listing!['title'] ?? 'Item';
      final price = double.tryParse(listing!['price']?.toString() ?? '0') ?? 0.0;

      // Use the actual NETS API following the document approach
      final result = await _netsService.generateQrCode(
        orderId: orderId!,
        amount: price,
        description: 'Purchase: $title',
      );

      if (result != null && result['success'] == true) {
        setState(() {
          qrCodeBase64 = result['qr_code'];
          txnRetrievalRef = result['txn_retrieval_ref'];
          isLoading = false;
        });

        // Start listening for payment updates via Server-Sent Events
        _startPaymentStatusListener();
        _startCountdownTimer();
        _startTimeoutTimer();

      } else {
        // Fallback to demo mode if API fails
        _generateDemoQr(price, title);
      }

    } catch (e) {
      print('Error with NETS API: $e');
      // Fallback to demo mode
      final price = double.tryParse(listing!['price']?.toString() ?? '0') ?? 0.0;
      final title = listing!['title'] ?? 'Item';
      _generateDemoQr(price, title);
    }
  }

  void _generateDemoQr(double price, String title) {
    // Demo QR for testing when NETS API is not available
    final demoQrData = _netsService.generateDemoQrData(
      orderId: orderId!,
      amount: price,
    );

    setState(() {
      qrCodeBase64 = base64Encode(utf8.encode(demoQrData)); // Simulate base64 QR
      isLoading = false;
    });

    _startCountdownTimer();
    _startDemoPaymentFlow();
  }

  void _startPaymentStatusListener() {
    if (txnRetrievalRef == null) return;

    // Listen to Server-Sent Events for real-time updates
    _paymentStream = _netsService.listenForPaymentUpdates(txnRetrievalRef!)
        .listen((update) {
      if (update['success'] == true) {
        final status = update['status'];
        final responseCode = update['response_code'];

        if (status == 'S' && responseCode == '00') {
          // Payment successful
          _handlePaymentSuccess();
        } else if (status == 'F') {
          // Payment failed
          _handlePaymentFailure('Payment failed: ${update['message']}');
        }
        // 'P' = Pending, continue waiting
      }
    }, onError: (error) {
      print('Payment stream error: $error');
      // Fallback to manual checking
      _startManualStatusCheck();
    });
  }

  void _startManualStatusCheck() {
    if (txnRetrievalRef == null) return;

    Timer.periodic(Duration(seconds: 3), (timer) {
      if (isPaymentCompleted || isPaymentFailed) {
        timer.cancel();
        return;
      }

      _netsService.checkTransactionStatus(txnRetrievalRef!).then((result) {
        if (result != null && result['success'] == true) {
          final status = result['status'];

          if (status == 'S') {
            timer.cancel();
            _handlePaymentSuccess();
          } else if (status == 'F') {
            timer.cancel();
            _handlePaymentFailure('Transaction failed');
          }
        }
      });
    });
  }

  void _startDemoPaymentFlow() {
    // Demo mode - auto complete after 15 seconds for testing
    Timer(Duration(seconds: 15), () {
      if (!isPaymentCompleted && !isPaymentFailed) {
        _handlePaymentSuccess();
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
      });

      if (remainingSeconds <= 0) {
        timer.cancel();
        if (!isPaymentCompleted && !isPaymentFailed) {
          _handlePaymentFailure('Transaction timed out');
        }
      }
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(Duration(minutes: 5), () {
      if (!isPaymentCompleted && !isPaymentFailed) {
        _handlePaymentFailure('Payment session expired');
      }
    });
  }

  void _handlePaymentSuccess() {
    setState(() {
      isPaymentCompleted = true;
      statusMessage = 'Payment Successful!';
    });

    // Send success notification
    final price = double.tryParse(listing!['price']?.toString() ?? '0') ?? 0.0;
    _notificationService.showPaymentSuccessNotification(
      orderId: orderId!,
      amount: price,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back after delay
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context, {'success': true, 'orderId': orderId});
      }
    });
  }

  void _handlePaymentFailure(String message) {
    setState(() {
      isPaymentFailed = true;
      statusMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildQrCodeWidget() {
    if (qrCodeBase64 != null) {
      try {
        // If it's a base64 image (from real NETS API)
        if (qrCodeBase64!.startsWith('iVBOR') || qrCodeBase64!.startsWith('/9j/')) {
          final bytes = base64Decode(qrCodeBase64!);
          return Image.memory(bytes, width: 250, height: 250);
        } else {
          // If it's our demo data, generate QR code
          final qrData = String.fromCharCodes(base64Decode(qrCodeBase64!));
          return QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 250.0,
            backgroundColor: Colors.white,
          );
        }
      } catch (e) {
        // Fallback QR generation
        return QrImageView(
          data: qrCodeBase64!,
          version: QrVersions.auto,
          size: 250.0,
          backgroundColor: Colors.white,
        );
      }
    }

    return const CircularProgressIndicator();
  }

  @override
  Widget build(BuildContext context) {
    if (listing == null) {
      return Scaffold(
        backgroundColor: AppColour.background,
        appBar: AppBar(title: const Text('Payment Error')),
        body: const Center(child: Text('No item selected for payment')),
      );
    }

    final title = listing!['title'] ?? 'Item';
    final price = double.tryParse(listing!['price']?.toString() ?? '0') ?? 0.0;
    final sellerName = listing!['sellerName'] ?? 'Seller';

    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        title: const Text('NETS QR Payment'),
        backgroundColor: AppColour.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Payment Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.payment,
                    size: 48,
                    color: AppColour.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seller: $sellerName',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SGD \$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColour.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Status Display
            if (isPaymentCompleted) ...[
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      statusMessage,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Order ID: $orderId',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isPaymentFailed) ...[
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error,
                      size: 80,
                      color: Colors.red[600],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      statusMessage,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // QR Code Section
              Text(
                'Scan QR Code with NETS App',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Time remaining: ${_formatTime(remainingSeconds)}',
                style: TextStyle(
                  fontSize: 16,
                  color: remainingSeconds < 60 ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildQrCodeWidget(),
                    const SizedBox(height: 20),
                    Text(
                      'Order ID: $orderId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Demo button for testing
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Demo Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'For testing: Payment will be simulated automatically or use button below.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _handlePaymentSuccess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Simulate Payment Success'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Cancel Button
            if (!isPaymentCompleted && !isPaymentFailed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel Payment'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}