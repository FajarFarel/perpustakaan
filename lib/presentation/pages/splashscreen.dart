import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:perpustakaan/main.dart';
import 'package:perpustakaan/presentation/pages/admin.dart';
import 'package:perpustakaan/presentation/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash-screen';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

void _checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
  final loginTimeStr = prefs.getString("loginTime");

  await Future.delayed(const Duration(seconds: 3)); // waktu splash screen

  if (isLoggedIn && loginTimeStr != null) {
    final loginTime = DateTime.tryParse(loginTimeStr);
    final now = DateTime.now();

    if (loginTime != null && now.difference(loginTime).inMinutes <= 120) {
      // ✅ Auto-login masih berlaku
      final userData = jsonDecode(prefs.getString("user")!);
      final role = userData['role'];

      if (role == 'admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => AdminHomePage()));
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              name: userData['nama'],
              email: userData['email'],
              foto: userData['foto'],
              alamat: userData['alamat'],
              noTelp: userData['noTelp'],
              npm: userData['npm'],
            ),
          ),
        );
      }
    } else {
      // ✅ Lewat 2 jam, logout otomatis
      await prefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  } else {
    // Belum login sebelumnya
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple, // Warna latar belakang
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo_upn.png',
                    width: 150,
                  ).animate().scale(duration: 1000.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  Text(
                    'WELCOME',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black45,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 2000.ms),
                  const SizedBox(height: 10),
                  CircularProgressIndicator(
                    color: Colors.white,
                  ).animate().fadeIn(duration: 2500.ms),
                ],
              ),
            ),
          ),

          // Copyright text di bagian bawah
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '© 2025 SagiScorp. All Rights Reserved.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ).animate().fadeIn(duration: 3000.ms),
          ),
        ],
      ),
    );
  }
}
