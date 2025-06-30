import 'package:flutter/material.dart';
import 'package:trashure/models/colours.dart';
import 'package:trashure/screens/home_screen.dart';
import 'package:trashure/widgets/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  static const routeName = '/register';
  RegisterScreen({super.key});

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColour.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              //Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Profile circle
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.transparent,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 64,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              //Profile Pic
              OutlinedButton(
                onPressed: () {},
                child: const Text('Select Profile Picture'),
              ),

              const SizedBox(height: 24),

              //Username
              CustomTextField(
                label: 'Username',
                hintText: 'John Doe',
                controller: usernameController,
              ),
              const SizedBox(height: 16),

              //Email
              CustomTextField(
                label: 'Email',
                hintText: 'Johndoe@gmail.com',
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
              ),
              const SizedBox(height: 16),

              //Phone number
              CustomTextField(
                label: 'Phone Number',
                hintText: '98761234',
                keyboardType: TextInputType.phone,
                controller: phoneController,
              ),
              const SizedBox(height: 16),

              //Password
              CustomTextField(
                label: 'Password',
                hintText: '********',
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 60),

              //Create account
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.black),
                  ),
                ),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
