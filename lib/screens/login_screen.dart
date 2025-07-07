import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:trashure/models/colours.dart';
import 'package:trashure/services/firebase_service.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forget_password_screen.dart';
import 'home_screen.dart';
import 'package:trashure/screens/forget_password_screen.dart';
import 'package:trashure/screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginScreen extends StatelessWidget {
  static const routeName = '/login';

  final FirebaseService fbService = GetIt.instance<FirebaseService>();
  final GlobalKey<FormState> form = GlobalKey<FormState>();

  String? email;
  String? password;

  LoginScreen({super.key});

  void login(BuildContext context) async {
    final isValid = form.currentState!.validate();
    if (isValid) {
      form.currentState!.save();
      try {
        await fbService.login(email, password);
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User logged in successfully!')),
        );
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      }
      on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.code)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColour.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: form,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const CircleAvatar(
                    radius: 80,
                    backgroundImage: AssetImage('images/logo.png'),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  CustomTextField(
                    hintText: 'Email',
                    controller: TextEditingController(),
                    keyboardType: TextInputType.emailAddress,
                    // Save and validate email
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    onSaved: (value) => email = value,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    hintText: 'Password',
                    obscureText: true,
                    controller: TextEditingController(),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => password = value,
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

                  // Login Button
                  ElevatedButton(
                    onPressed: () => login(context),
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
      ),
    );
  }
}
