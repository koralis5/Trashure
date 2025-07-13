import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:trashure/models/colours.dart';
import 'package:trashure/services/firebase_service.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forget_password_screen.dart';
import 'home_screen.dart';
import 'phone_login_screen.dart';
import 'email_verification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
      final userCred = await fbService.login(email!, password!);
      final user = userCred.user;

      if (user == null) {
        throw Exception('Login failed: No user returned.');
      }

      await user.reload(); // Refresh user
      final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;


      if (!isVerified) {
        await fbService.sendEmailVerification();
        Navigator.pushReplacementNamed(context, EmailVerificationScreen.routeName);
        return;
      }

      FocusScope.of(context).unfocus();
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

                  ElevatedButton(
                    onPressed: googleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'images/google_icon.png',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text('Sign in with Google'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Facebook Login (I give up, it maybe could have worked on Android, but not on website)
                  /*
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final credential = await fbService.signInWithFacebook();
                        if (credential.user != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Facebook sign-in successful'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Facebook login failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    label: const Text('Sign in with Facebook'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                  */

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Sign in with Phone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
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
