import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uiux/controllers/auth_controller.dart';
import 'package:uiux/core/colors.dart';
import 'package:uiux/providers/navigation_provider.dart';
import 'package:uiux/views/auth/signup_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController _controller; // Use LoginController instead

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: Container(
        margin: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _header(context),
            _inputField(context, navigationProvider),
            _forgotPassword(context),
            _signup(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return const Column(
      children: [
        Text(
          "Welcome Back",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text("Enter your credentials to login"),
      ],
    );
  }

  Widget _inputField(BuildContext context, NavigationProvider navigationProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: "Username",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: AppColors.bg.withOpacity(0.5),
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller.passwordController,
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: AppColors.bg.withOpacity(0.5),
            filled: true,
            prefixIcon: const Icon(Icons.lock),
          ),
          obscureText: true,
          onChanged: (value) => _controller.validatePasswords(),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _controller.errorNotifier,
          builder: (context, error, child) {
            return error != null
                ? Text(error, style: const TextStyle(color: Colors.red, fontSize: 14))
                : const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            _controller.validatePasswords();
            if (_controller.errorNotifier.value == null) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              navigationProvider.setSelectedIndex(0);
            }
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.activeBtn,
          ),
          child: const Text(
            "Login",
            style: TextStyle(fontSize: 20, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _forgotPassword(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: const Text(
        "Forgot password?",
        style: TextStyle(color: AppColors.hypertext),
      ),
    );
  }

  Widget _signup(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SignupPage()),
            );
          },
          child: const Text("Sign Up", style: TextStyle(color: AppColors.hypertext)),
        ),
      ],
    );
  }
}
