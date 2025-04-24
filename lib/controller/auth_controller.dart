import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:perpustakaan/model/admin.dart';
import 'package:perpustakaan/model/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../penting/constants.dart';

class AuthController extends GetxController {
  var userRole = ''.obs;
  static AuthController instance = Get.find();

  void loginUser(BuildContext context, String email, String password) async {
    var url = Uri.parse('$baseUrl/login'); // Ganti dengan URL backend

    print("🔄 Mengirim data login...");
    print("Email: $email, Password: $password");

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("📥 Response status: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var user = responseData['user'];
        var userRole = user['role'];

        print("✅ Login Berhasil!");
        print("User Data: $responseData");

        // Simpan data ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user", jsonEncode(user));
        await prefs.setString("npm", user['npm']); // ✅ Tambahkan ini
        await prefs.setString("loginTime", DateTime.now().toIso8601String());
        await prefs.setBool("isLoggedIn", true);
        

        // Navigasi ke halaman sesuai role
        if (userRole == 'admin') {
          print("🚀 Navigasi ke AdminHomePage");
          Get.offAll(() => AdminHomePage());
        } else {
          print("🚀 Navigasi ke HomePage");
          Get.offAll(() => HomePage(
                name: user['nama'],
                email: user['email'],
                foto: user['foto'], // Kirim URL, bukan File
                alamat: user['alamat'],
                noTelp: user['noTelp'],
                npm: user['npm'],
              ));
        }
      } else {
        print("❌ Gagal Login: ${response.body}");
        Get.snackbar('Login Gagal', 'Email atau password salah');
      }
    } catch (e) {
      print("❌ Error: $e");
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    }
  }
}
