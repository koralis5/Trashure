import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  Future<UserCredential> register(email, password) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password:
    password);
  }
  Future<UserCredential> login(email, password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password:
    password);
  }
  Stream<User?> getAuthUser() {
    return FirebaseAuth.instance.authStateChanges();
  }
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }
  Future<void> logOut() {
    return FirebaseAuth.instance.signOut();
  }

  Future<void> resetPassword(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}