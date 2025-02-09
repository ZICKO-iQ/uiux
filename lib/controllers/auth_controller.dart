import 'package:flutter/material.dart';

class SignupController {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  void validatePasswords() {
    if (passwordController.text.isEmpty) {
      errorNotifier.value = "Please enter a password";
    } else if (passwordController.text.length <= 7) {
      errorNotifier.value = "Password must be at least 8 characters";
    } else if (passwordController.text != confirmPasswordController.text) {
      errorNotifier.value = "Passwords don't match";
    } else {
      errorNotifier.value = null;
    }
  }

  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    errorNotifier.dispose();
  }
}

class LoginController {
  final TextEditingController passwordController = TextEditingController();
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  void validatePasswords() {
    if (passwordController.text.isEmpty) {
      errorNotifier.value = "Please enter your password";
    } else if (passwordController.text.length <= 7) {
      errorNotifier.value = "the Password is Not Correct";
    } else {
      errorNotifier.value = null;
    }
  }

  void dispose() {
    passwordController.dispose();
    errorNotifier.dispose();
  }
}
