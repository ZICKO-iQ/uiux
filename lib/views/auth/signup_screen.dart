import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uiux/core/colors.dart';
import 'package:uiux/providers/navigation_provider.dart';
import 'package:uiux/views/auth/login_screen.dart';
import 'package:uiux/controllers/auth_controller.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late final SignupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignupController(); // Initialize once
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          height: MediaQuery.of(context).size.height - 50,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Column(
                children: const [
                  SizedBox(height: 60.0),
                  Text(
                    "Sign up",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Create your account",
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  )
                ],
              ),
              Column(
                children: <Widget>[
                  _buildTextField("Username", Icons.person),
                  const SizedBox(height: 20),
                  _buildTextField("Email", Icons.email),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller.passwordController,
                    obscureText: true,
                    decoration: _inputDecoration("Password", Icons.lock),
                    onChanged: (value) => _controller.validatePasswords(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller.confirmPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration("Confirm Password", Icons.lock),
                    onChanged: (value) => _controller.validatePasswords(),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: _controller.errorNotifier,
                    builder: (context, error, child) {
                      return error != null
                          ? Text(error, style: TextStyle(color: Colors.red, fontSize: 14))
                          : const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Phone Number", Icons.phone),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(top: 3, left: 3),
                child: ElevatedButton(
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
                    "Sign up",
                    style: TextStyle(fontSize: 20, color: AppColors.textPrimary),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(color: AppColors.hypertext),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, IconData icon) {
    return TextField(
      decoration: _inputDecoration(hintText, icon),
    );
  }

  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      fillColor: AppColors.bg.withOpacity(0.5),
      filled: true,
      prefixIcon: Icon(icon),
    );
  }
}
