import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:len_den/screens/homepage_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:len_den/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  static const String id = "Login Screen";
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;
  User user;

  bool validatePassword(String value) {
    String pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regExp = new RegExp(pattern);
    return regExp.hasMatch(value);
  }

  Future<String> _authSignin(LoginData data) async {
    try {
      user = (await auth.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      ))
          .user;
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          return 'Please Verify Email First & Login Again';
        }
        return null;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
    }
    return 'Signing Failed';
  }

  Future<String> _authRegister(LoginData data) async {
    if (!EmailValidator.validate(data.name)) return 'Please Enter Valid Email';
    if (!validatePassword(data.password)) return 'Please Enter Strong Password';
    try {
      user = (await auth.createUserWithEmailAndPassword(
        email: data.name,
        password: data.password,
      ))
          .user;
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          return 'Please Verify Email First & Then Login';
        }
        return null;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      }
    }
    return 'Registration Failed';
  }

  Future<String> _recoverPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterLogin(
              title: 'Len Den',
              logo: 'images/logo.png',
              onLogin: _authSignin,
              onSignup: _authRegister,
              onSubmitAnimationCompleted: () async {
                bool hasVisited = await visitingFlag();
                if (hasVisited == true)
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => HomePage(),
                    ),
                  );
                else
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => OnBoardingPage(),
                    ),
                  );
              },
              onRecoverPassword: _recoverPassword,
            ),
          ],
        ),
      ),
    );
  }
}

visitingFlag() async {
  SharedPreferences preference = await SharedPreferences.getInstance();
  // Get Visiting Flag
  bool hasVisited = preference.getBool("hasVisited") ?? false;
  // Set Visiting Flag
  preference.setBool("hasVisited", true);
  return hasVisited;
}
