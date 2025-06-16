import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class Pengaturan extends StatefulWidget {
  const Pengaturan({super.key});

  @override
  State<Pengaturan> createState() => _PengaturanState();
}

class _PengaturanState extends State<Pengaturan> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.snackbar('Sukses', 'Data pengguna telah dihapus!', snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Mode Gelap"),
            subtitle: const Text("Aktifkan untuk mode gelap"),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              _updateSetting('darkMode', value);
            },
          ),
          SwitchListTile(
            title: const Text("Notifikasi Peminjaman"),
            subtitle: const Text("Terima pemberitahuan tentang peminjaman buku"),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _updateSetting('notifications', value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Kelola Akun"),
            onTap: () => Get.toNamed('/kelolaAkun'),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Hapus Data Pengguna"),
            onTap: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi"),
                  content: const Text("Apakah Anda yakin ingin menghapus semua data pengguna?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Ya"),
                    ),
                  ],
                ),
              );
              if (confirm) {
                _clearData();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
