import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uiux/core/colors.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class LoginRoute extends StatefulWidget {
  const LoginRoute({super.key});

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Center(
              child: Column(
                children: [
                  SvgPicture.asset(
                      'assets/images/arkhasluk-logo-clr.svg',  
                      width: 150,  // Set the width
                      height: 150,  // Set the height
                    ),
                  SizedBox(height: 20,),
                  Text('Arkhasluk', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),)
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              children: [
                Text('Welcome!', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                SizedBox(height: 20,),
                ElevatedButton(
                  onPressed: () { Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
                    foregroundColor: AppColors.bgWhite, backgroundColor: AppColors.primary, // Text color
                    minimumSize: const Size(200, 50), // Button size
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 20),),
                ),
                SizedBox(height: 10,),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SignupPage()));
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
                    foregroundColor: AppColors.primary, side: BorderSide(width: 2, color: AppColors.primary), // Text color
                    minimumSize: const Size(200, 50), // Button size
                    backgroundColor: Colors.white, // Button background color
                  ),
                  child: const Text('Sign up', style: TextStyle(fontSize: 20),),
                ),
                SizedBox(height: 10,),
                Text('--------------------------- Sign in with ---------------------------'),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary, side: BorderSide(width: 2, color: AppColors.primary), // Text color
                            minimumSize: const Size(75, 75), // Button size
                            backgroundColor: Colors.white, // Button background color
                            shape: const CircleBorder(),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/Google.svg',  // Path to your SVG file
                            width: 40,  // Set the width
                            height: 40,  // Set the height
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary, side: BorderSide(width: 2, color: AppColors.primary), // Text color
                            minimumSize: const Size(75, 75), // Button size
                            backgroundColor: Colors.white, // Button background color
                            shape: const CircleBorder(),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/Facebook.svg',  // Path to your SVG file
                            width: 40,  // Set the width
                            height: 40,  // Set the height
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary, side: BorderSide(width: 2, color: AppColors.primary), // Text color
                            minimumSize: const Size(75, 75), // Button size
                            backgroundColor: Colors.white, // Button background color
                            shape: const CircleBorder(),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/Apple.svg',  // Path to your SVG file
                            width: 40,  // Set the width
                            height: 40,  // Set the height
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
