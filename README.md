📚 Perpustakaan Digital
Aplikasi Perpustakaan Digital yang memungkinkan pengguna untuk melakukan peminjaman, pengembalian, dan manajemen buku secara online. Aplikasi ini mendukung fitur notifikasi pengembalian, autentikasi pengguna, serta manajemen admin.

🧩 Fitur Utama
🔐 Login & Register Mahasiswa
📖 Lihat Daftar Buku
🛒 Peminjaman & Pengembalian Buku
🔔 Notifikasi Pengingat Pengembalian Buku
📊 Halaman Admin (Manajemen Buku & User)
🧾 Riwayat Peminjaman
📸 Upload Sampul Buku


🛠️ Teknologi yang Digunakan
Frontend (Flutter)
Flutter SDK
http – untuk komunikasi API
shared_preferences – menyimpan data lokal
flutter_local_notifications – notifikasi pengingat
provider & get – manajemen state
Backend (Flask)
REST API
MySQL

🗃️ Struktur Database (Contoh)
Tabel Mahasiswa
id, nama, npm, email, password
Tabel Buku
id, judul, penulis, isbn, jumlah, foto
Tabel Peminjaman
id, id_buku, id_mahasiswa, tanggal_pinjam, tanggal_kembali, status

🚀 Cara Menjalankan Aplikasi
Backend
bash
Salin
Edit
cd backend
python app.py
Frontend
bash
Salin
Edit
cd perpustakaan_flutter
flutter pub get
flutter run

📌 Catatan
Notifikasi pengembalian muncul 3 hari sebelum batas waktu pengembalian.
Buku yang telah dikembalikan tidak muncul di halaman peminjaman aktif.
Hanya admin yang bisa mengelola data buku dan pengguna.

✍️ Kontributor
Fajar – Pengembang Utama
Leo – Asisten AI 😄
