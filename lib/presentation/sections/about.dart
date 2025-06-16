import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:perpustakaan/core/colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          title: const Text(
            "About This App",
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.secondary,
          iconTheme: const IconThemeData(
            color: AppColors.textPrimary, // Change the color of the back button
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "About This App",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Selamat datang di Library App, platform perpustakaan digital yang dirancang untuk memudahkan akses dan manajemen koleksi buku secara efisien.\n",
                style: TextStyle(color: AppColors.textSecondary,  fontSize: 16),
              ),
              const Text(
                "Fitur Utama:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                  "📚 Katalog Buku – Jelajahi berbagai koleksi buku yang tersedia di perpustakaan.", style: TextStyle(color: AppColors.textSecondary)),
              const Text(
                  "🔍 Pencarian Cepat – Temukan buku favoritmu dengan fitur pencarian yang akurat.", style: TextStyle(color: AppColors.textSecondary)),
              const Text(
                  "📖 Peminjaman & Pengembalian – Kelola pinjaman buku dengan mudah dan perbarui status stok secara real-time.",  style: TextStyle(color: AppColors.textSecondary)),
              const Text(
                  "💾 Manajemen Data – Data buku dan peminjaman tersimpan dengan aman.",  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Text(
                "Aplikasi ini dikembangkan oleh SagiScorp dengan dedikasi untuk menciptakan solusi digital yang inovatif dan bermanfaat.",
                 style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                "Saya sebagai pengembang dari aplikasi ini sangat menghargai masukan dan saran serta kritik dari pengguna. jika kalian para mahasiswa/i yang ingin memberikan masukan, kritik, atau saran, silakan hubungi saya melalui halaman help di aplikasi ini.",
                 style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.primary,
                child: Center(
                  child: Text(
                    '© 2025 SagiScorp. All Rights Reserved.',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  ).animate().fadeIn(duration: 2000.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
