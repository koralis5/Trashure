import 'package:flutter/material.dart';
import 'package:trashure/models/colours.dart';
import 'package:trashure/widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatelessWidget {
  static const routeName = '/reset-password';

  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColour.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
              const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Email Field with Send Verification
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Email',
                      hintText: 'Johndoe@gmail.com',
                      controller: emailController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Verification email sent")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Send Verification"),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // New Password Field
              CustomTextField(
                label: 'New Password',
                hintText: '********',
                controller: passwordController,
                obscureText: true,
              ),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password updated")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text("Update Password"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
