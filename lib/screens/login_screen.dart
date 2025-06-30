import 'package:flutter/material.dart';
import 'package:trashure/models/colours.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forget_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColour.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const CircleAvatar(
                  radius: 80,
                  backgroundImage: AssetImage('images/logo.png'),
                ),
                const SizedBox(height: 40),

                CustomTextField(
                  hintText: 'Email',
                  controller: emailController,
                ),
                SizedBox(height: 16),
                CustomTextField(
                  hintText: 'Password',
                  obscureText: true,
                  controller: passwordController,
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, ResetPasswordScreen.routeName);
                    },
                    child: const Text(
                      'Forgot your password?',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                //Login Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 14),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Login"),
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, RegisterScreen.routeName);
                  },
                  child: const Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
