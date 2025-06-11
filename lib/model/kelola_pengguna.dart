import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:perpustakaan/penting/constants.dart';

class KelolaPengguna extends StatefulWidget {
  const KelolaPengguna({super.key});

  @override
  State<KelolaPengguna> createState() => _KelolaPenggunaState();
}

class _KelolaPenggunaState extends State<KelolaPengguna> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

Future<void> fetchUsers() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    print("Raw Response: ${response.body}");

    if (response.statusCode == 200) {
      var decodedData = json.decode(response.body);
      print("Decoded Data: $decodedData");

      if (decodedData is List) {
        setState(() {
          users = decodedData;
        });
      } else if (decodedData is Map && decodedData.containsKey('users')) {
        setState(() {
          users = decodedData['users'];
        });
      } else {
        throw Exception("Format data tidak sesuai");
      }
    } else {
      throw Exception("Gagal mengambil data pengguna, status: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Pengguna")),
      body: users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index];

                print("User ke-$index: $user"); // Debugging untuk cek isi user

                if (user is! Map ||
                    !user.containsKey('nama') ||
                    !user.containsKey('email')) {
                  return ListTile(title: Text("Data tidak valid"));
                }

                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user['nama']?.toString() ?? "Tanpa Nama"),
                  subtitle: Text(user['email']?.toString() ?? "Tanpa Email"),
                );
              }),
    );
  }
}
