import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:perpustakaan/core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:perpustakaan/core/colors.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({Key? key}) : super(key: key);

  @override
  _BookScreenState createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  List<Map<String, dynamic>> books = [];
  Set<String> sudahDiberiNotifikasi = {};
  int totalDenda = 0;
  int? idMahasiswa;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifikasi();
    ambilDataAwal();
  }

 Future<void> ambilDataAwal() async {
final prefs = await SharedPreferences.getInstance();
final npm = prefs.getString('npm');
if (npm != null) await ambilTotalDenda(npm);

  if (npm != null) {
    await ambilTotalDenda(npm);
    await ambilPeminjamanSaya(npm);
  } else {
    print('❌ Gagal ambil NPM dari SharedPreferences');
  }
}

Future<void> ambilTotalDenda(String npm) async {
  try {
    final res = await http.get(Uri.parse('$baseUrl/cek_denda_npm/$npm'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        totalDenda = data['total_denda'] ?? 0;
      });
    } else {
      print('Gagal ambil denda: ${res.statusCode}');
    }
  } catch (e) {
    print('Error ambil denda: $e');
  }
}


  void _initNotifikasi() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('ic_stat_logo');

    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void showNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'reminder_channel',
      'Pengingat Pengembalian',
      channelDescription: 'Notifikasi pengingat buku',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: 'ic_stat_logo',
      playSound: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      message,
      platformDetails,
    );
  }

  int calculateRemainingDays(DateTime returnDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(returnDate.year, returnDate.month, returnDate.day);
    return target.difference(today).inDays;
  }

  Future<void> ambilPeminjamanSaya(String npm) async {
    final response = await http.get(Uri.parse('$baseUrl/peminjaman_user/$npm'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      final List<Map<String, dynamic>> bukuDipinjam =
          jsonData.where((item) => item['status'] == 'dipinjam').map((item) {
        final borrowDate = DateTime.parse(item['borrowDate']);
        final returnDate = DateTime.parse(item['returnDate']);
        final remainingDays = calculateRemainingDays(returnDate);
        final isbn = item['isbn'];

        if (remainingDays <= 3 &&
            remainingDays >= 0 &&
            !sudahDiberiNotifikasi.contains(isbn)) {
          showNotification(
            '📚 Pengingat Pengembalian Buku',
            'Buku "${item['title']}" harus dikembalikan dalam $remainingDays hari!',
          );
          sudahDiberiNotifikasi.add(isbn);
        }

        return {
          'title': item['title'],
          'isbn': isbn,
          'borrowDate': borrowDate,
          'returnDate': returnDate,
          'cover': item['cover'] ?? 'assets/placeholder.jpg',
        };
      }).toList();

      setState(() {
        books = bukuDipinjam;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gradientTop,
              AppColors.gradientBottom,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              "Library Books",
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.secondary,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Denda: Rp$totalDenda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: totalDenda > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ),
              Expanded(
                child: books.isEmpty
                    ? Center(
                        child: Opacity(
                          opacity: 0.6,
                          child: Image.asset(
                            'assets/bookshelf_1.png',
                            width: 160,
                            height: 160,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          final borrowDate = book['borrowDate'] as DateTime;
                          final returnDate = book['returnDate'] as DateTime;
                          final remainingDays =
                              calculateRemainingDays(returnDate);

                          String warningMessage = '';
                          if (remainingDays <= 3 && remainingDays >= 0) {
                            warningMessage =
                                "⚠️ Hati-hati! Waktu pengembalian tinggal $remainingDays hari lagi.";
                          } else if (remainingDays < 0) {
                            warningMessage =
                                "❌ Buku sudah melewati batas waktu pengembalian!";
                          }

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            color: AppColors.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '📚 Judul: ${book['title'] ?? 'Tidak tersedia'}'),
                                  SizedBox(height: 8),
                                  Text(
                                      'Tanggal Peminjaman: ${borrowDate.toLocal().toString().split(" ")[0]}'),
                                  Text(
                                      'Tanggal Pengembalian: ${returnDate.toLocal().toString().split(" ")[0]}'),
                                  if (warningMessage.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    Text(warningMessage,
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ));
  }
}
