import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:trashure/models/colours.dart';
import 'package:trashure/services/firebase_service.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forget_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService fbService = GetIt.instance<FirebaseService>();
  final GlobalKey<FormState> form = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? email;
  String? password;

  Future<void> login(BuildContext context) async {
    if (!form.currentState!.validate()) return;
    form.currentState!.save();

    try {
      await fbService.login(email!, password!);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User logged in successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> googleLogin() async {
    try {
      final credential = await fbService.googleSignIn();
      if (credential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in successful'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

                  CustomTextField(
                    hintText: 'Email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    onSaved: (value) => email = value,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    hintText: 'Password',
                    obscureText: true,
                    controller: passwordController,
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

                  ElevatedButton(
                    onPressed: () => login(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 14),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Login"),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: googleLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
      ),
    );
  }
}
