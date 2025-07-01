import 'package:flutter/material.dart';
import 'package:trashure/screens/login_screen.dart';
import 'package:trashure/screens/select_listing_image.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/add_listing_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/own_listing_screen.dart';
import 'screens/edit_listing_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'services/firebase_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  GetIt.instance.registerLazySingleton(() => FirebaseService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => LoginScreen(),
        RegisterScreen.routeName: (_) => RegisterScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
        AddListingScreen.routeName: (_) => AddListingScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        SelectListingImage.routeName: (_) => const SelectListingImage(),
        OwnListingScreen.routeName: (_) => const OwnListingScreen(),
        EditListingScreen.routeName: (_) => const EditListingScreen(),
        EditProfileScreen.routeName: (_) => const EditProfileScreen()
      },
    );
  }
}