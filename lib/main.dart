import 'package:flutter/material.dart';
import 'package:trashure/screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/add_listing_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_listing_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/map_picker_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/setup.dart';
import 'screens/email_verification_screen.dart';
import 'screens/listing_detail_screen.dart';
import 'screens/qr_payment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setupServices();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService fbService = GetIt.instance<FirebaseService>();

    return StreamBuilder<User?>(
      stream: fbService.getAuthUser(),
      builder: (context, snapshot) {
        Widget startingPage;

        if (snapshot.connectionState == ConnectionState.waiting) {
          // While checking auth state, show a splash or loading
          startingPage = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.emailVerified || user.providerData.any((info) => info.providerId == 'google.com')) {
            startingPage = const HomeScreen(); // Email verified or using Google
          } else {
            startingPage = const EmailVerificationScreen(); // Not verified
          }
        } else {
          startingPage = const LoginScreen(); // Not logged in
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: startingPage,
          routes: {
            LoginScreen.routeName: (_) => const LoginScreen(),
            RegisterScreen.routeName: (_) => const RegisterScreen(),
            HomeScreen.routeName: (_) => const HomeScreen(),
            ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
            AddListingScreen.routeName: (_) => const AddListingScreen(),
            ProfileScreen.routeName: (_) => const ProfileScreen(),
            ListingDetailScreen.routeName: (_) => const ListingDetailScreen(),
            EditListingScreen.routeName: (_) => const EditListingScreen(),
            EditProfileScreen.routeName: (_) => const EditProfileScreen(),
            EmailVerificationScreen.routeName: (_) => const EmailVerificationScreen(),
            MapPickerScreen.routeName: (_) => const MapPickerScreen(),
            QrPaymentScreen.routeName: (_) => const QrPaymentScreen(),
          },
        );
      },
    );
  }
}