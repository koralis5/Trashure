import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:trashure/services/firebase_service.dart';
import 'package:trashure/screens/home_screen.dart';
import 'package:trashure/models/colours.dart';

class EmailVerificationScreen extends StatefulWidget {
  static const routeName = '/verify_email';

  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final fbService = GetIt.I<FirebaseService>();
  bool isChecking = false;
  bool isVerified = false;

  Future<void> checkVerification() async {
    setState(() => isChecking = true);
    final verified = await fbService.isEmailVerified();

    if (verified) {
      setState(() => isVerified = true);
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } else {
      setState(() => isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not verified yet')),
      );
    }
  }

  Future<void> resendVerification() async {
    await fbService.sendEmailVerification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email resent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Verify Email", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, size: 100, color: AppColour.primaryGreen),
              const SizedBox(height: 24),
              const Text(
                "A verification email has been sent to your email address.\nPlease verify before proceeding.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColour.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: isChecking ? null : checkVerification,
                  icon: const Icon(Icons.refresh),
                  label: Text(isChecking ? 'Checking...' : 'Check Verification'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: resendVerification,
                child: const Text(
                  "Resend Verification Email",
                  style: TextStyle(color: AppColour.primaryGreen),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                child: const Text(
                  "Back to Login",
                  style: TextStyle(color: AppColour.primaryGreen),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }
}
