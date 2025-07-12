import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:trashure/services/firebase_service.dart';
import 'package:trashure/models/colours.dart'; // Assuming colors.dart contains AppColour
import 'home_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  static const routeName = '/phone_login';
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final fbService = GetIt.instance<FirebaseService>();
  final phoneController = TextEditingController();
  final smsController = TextEditingController();

  String? verificationId;
  bool codeSent = false;
  bool isLoading = false;
  bool showPassword = false;

  Future<void> sendCode() async {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a phone number")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await fbService.sendVerificationCode(
        phoneNumber: phoneController.text.trim(),
        codeSent: (String id) {
          setState(() {
            verificationId = id;
            codeSent = true;
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Verification code sent!")),
          );
        },
        onError: (e) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.message}")),
          );
        },
        onAutoVerified: (user) {
          Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        },
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send code: ${e.toString()}")),
      );
    }
  }

  Future<void> verifyCode() async {
    if (verificationId == null || smsController.text.trim().isEmpty) return;

    setState(() => isLoading = true);

    try {
      final userCred = await fbService.verifySmsCode(
        verificationId: verificationId!,
        smsCode: smsController.text.trim(),
      );

      if (userCred.user != null) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        title: const Text(
          "Phone Login",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              codeSent ? "Enter Verification Code" : "Enter Your Phone Number",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!codeSent) ...[
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1 234 567 8900',
                  prefixIcon: const Icon(Icons.phone, color: AppColour.primaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColour.primaryGreen),
                  ),
                ),
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16),
              ),
            ] else ...[
              TextField(
                controller: smsController,
                decoration: InputDecoration(
                  labelText: '6-digit Code',
                  prefixIcon: const Icon(Icons.sms, color: AppColour.primaryGreen),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColour.primaryGreen,
                    ),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColour.primaryGreen),
                  ),
                ),
                keyboardType: TextInputType.number,
                obscureText: !showPassword,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : (codeSent ? verifyCode : sendCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColour.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                codeSent ? 'Verify Code' : 'Send Verification Code',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (codeSent) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: sendCode,
                child: Text(
                  "Resend Code",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColour.primaryGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}