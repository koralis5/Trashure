import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class NetsQrService {
  // NETS OPENAPIPASS URLs (from your mini-project document)
  static const String _baseUrl = 'https://sandbox.nets.com.sg';

  // Replace these with your actual credentials from OPENAPIPASS
  static const String _apiKey = 'lsYvSBBRbkRUSDnytq92'; // From page 4, step 8
  static const String _projectId = 'c71e8358-7065-4a27-96f8-48867389148e'; // From page 4, step 7

  // RequestAPI - Generate QR Code (following the document's approach)
  Future<Map<String, dynamic>?> generateQrCode({
    required String orderId,
    required double amount,
    required String description,
  }) async {
    try {
      final requestBody = {
        'txn_amount': (amount * 100).toInt(), // Convert to cents
        'order_id': orderId,
        'currency_code': 'SGD',
        'txn_type': 'QR-SGQR',
        'merchant_reference': description,
        'notify_url': 'https://your-webhook-url.com/webhook', // Optional
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/transactions/qr-dynamic/v2/payment/request'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': _apiKey,
          'project-id': _projectId,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'qr_code': data['qr_code'], // Base64 QR code image
          'txn_retrieval_ref': data['txn_retrieval_ref'], // For tracking
          'order_id': orderId,
        };
      } else {
        print('QR Generation failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Failed to generate QR code: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error generating QR code: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // S2SWebhookAPI - Listen for payment status (Server-Sent Events)
  Stream<Map<String, dynamic>> listenForPaymentUpdates(String txnRetrievalRef) async* {
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_baseUrl/transactions/qr-dynamic/v2/payment/webhook?txn_retrieval_ref=$txnRetrievalRef'),
      );

      request.headers.addAll({
        'api-key': _apiKey,
        'project-id': _projectId,
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (String line in response.stream.transform(utf8.decoder).transform(LineSplitter())) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              yield {
                'success': true,
                'status': data['txn_status'],
                'response_code': data['response_code'],
                'message': data['message'],
              };

              // Break the stream if transaction is completed (success or fail)
              if (data['txn_status'] == 'S' || data['txn_status'] == 'F') {
                break;
              }
            } catch (e) {
              print('Error parsing SSE data: $e');
            }
          }
        }
      }

      client.close();
    } catch (e) {
      yield {
        'success': false,
        'error': 'Stream error: $e',
      };
    }
  }

  // QueryAPI - Check transaction status
  Future<Map<String, dynamic>?> checkTransactionStatus(String txnRetrievalRef) async {
    try {
      final requestBody = {
        'txn_retrieval_ref': txnRetrievalRef,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/transactions/qr-dynamic/v2/payment/query'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': _apiKey,
          'project-id': _projectId,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['txn_status'], // S = Success, F = Failed, P = Pending
          'response_code': data['response_code'],
          'amount': data['txn_amount'],
          'order_id': data['order_id'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to check status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // For demo purposes - simulate the QR data format
  String generateDemoQrData({
    required String orderId,
    required double amount,
  }) {
    // This creates a demo QR that shows the transaction details
    final qrData = {
      'merchant': 'Trashure Marketplace',
      'amount': amount.toStringAsFixed(2),
      'currency': 'SGD',
      'orderId': orderId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'description': 'Marketplace Purchase',
    };

    return jsonEncode(qrData);
  }
}