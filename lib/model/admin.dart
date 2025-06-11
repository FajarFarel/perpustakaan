import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perpustakaan/controller/book_controller.dart';
import 'package:perpustakaan/main.dart'; // Ganti jika LoginPage di tempat lain
import 'package:perpustakaan/penting/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final BookController bookController = Get.put(BookController());
  late IO.Socket socket;

@override
void initState() {
  super.initState();
  fetchUsers();
  fetchStatistik();
  setupSocket(); // 🔥 connect socket
}

void setupSocket() {
  socket = IO.io(baseUrl, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': true,
  });

  socket.onConnect((_) {
    print('✅ Socket terhubung ke server');
  });

  socket.on('update_statistik', (_) {
    print('🔁 Event diterima: update_statistik');
    fetchStatistik(); // ⬅️ Refresh data saat event diterima
  });

  socket.onDisconnect((_) => print('❌ Socket disconnected'));
}


  var users = [].obs;
  var jumlahBukuDipinjam = 0.obs;
  var jumlahPeminjamanAktif = 0.obs;

  // Duplicate initState method removed

Future<void> fetchUsers() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      var decodedData = json.decode(response.body);

      if (decodedData is List) {
        users.value = decodedData;
      } else if (decodedData is Map && decodedData.containsKey('users')) {
        users.value = decodedData['users'];
      } else {
        throw Exception("Format data tidak sesuai");
      }
    } else {
      print("❌ Gagal ambil data pengguna: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error fetch users: $e");
  }
}

  Future<void> fetchStatistik() async {
    try {
      final bukuRes = await http.get(Uri.parse('$baseUrl/jumlah-buku-dipinjam'));
      final aktifRes = await http.get(Uri.parse('$baseUrl/jumlah-peminjaman-aktif'));

      if (bukuRes.statusCode == 200) {
        jumlahBukuDipinjam.value = json.decode(bukuRes.body)['jumlah'];
      }

      if (aktifRes.statusCode == 200) {
        jumlahPeminjamanAktif.value = json.decode(aktifRes.body)['jumlah'];
      }
    } catch (e) {
      print("❌ Error ambil statistik: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Statistik", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                children: [
                  Obx(() => _buildStatCard("Total Pengguna", "${users.length}", Icons.people)),
                  Obx(() => _buildStatCard("Peminjaman Aktif", "${jumlahPeminjamanAktif.value}", Icons.assignment)),
                  Obx(() => _buildStatCard("Buku Tersedia", "${bookController.dataBuku.length}", Icons.library_books)),
                  Obx(() => _buildStatCard("Buku Dipinjam", "${jumlahBukuDipinjam.value}", Icons.book)),               
                ],
              ),
            ),
            SizedBox(height: 20),
            Text("Aksi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                children: [
                  _buildActionCard("Kelola Pengguna", Icons.people, Colors.blue, "/kelolaPengguna", context),
                  _buildActionCard("Kelola Buku", Icons.book, Colors.green, "/kelolaBuku", context),
                  // _buildActionCard("Pengaturan", Icons.settings, Colors.orange, "/pengaturan", context),
                  // _buildActionCard("Laporan", Icons.bar_chart, Colors.red, "/laporan", context),
                  _buildActionCard("Logout", Icons.logout, Colors.grey, "/logout", context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(count, style: TextStyle(fontSize: 18, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, String route, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (title == "Logout") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
            (route) => false,
          );
        } else {
          Get.toNamed(route);
        }
      },
      child: Card(
        color: color,
        elevation: 5,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
  @override
void dispose() {
  socket.dispose(); // nutup koneksi websocket biar gak bocor
  super.dispose();
}

}
