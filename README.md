
# 📚 Perpustakaan Digital

![GitHub repo size](https://img.shields.io/github/repo-size/FajarFarel/perpustakaan)
![GitHub stars](https://img.shields.io/github/stars/FajarFarel/perpustakaan?style=social)
![GitHub last commit](https://img.shields.io/github/last-commit/FajarFarel/perpustakaan)

Aplikasi **Perpustakaan Digital** yang memungkinkan pengguna untuk melakukan **peminjaman, pengembalian, dan manajemen buku** secara online. Aplikasi ini dilengkapi dengan **notifikasi pengingat pengembalian**, **login mahasiswa**, dan **halaman admin**.

---

## 🧩 Fitur Utama

- 🔐 **Login & Register Mahasiswa**
- 📖 **Lihat Daftar Buku**
- 🛒 **Peminjaman & Pengembalian Buku**
- 🔔 **Notifikasi Pengingat Pengembalian Buku**
- 📊 **Halaman Admin (Manajemen Buku & User)**
- 🧾 **Riwayat Peminjaman**
- 📸 **Upload Sampul Buku**

---

## 🛠️ Teknologi yang Digunakan

### 📱 Frontend (Flutter)

- Flutter SDK
- [`http`](https://pub.dev/packages/http) – komunikasi API
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) – penyimpanan lokal
- [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) – notifikasi
- [`provider`](https://pub.dev/packages/provider) & [`get`](https://pub.dev/packages/get) – manajemen state

### 🌐 Backend (Flask)

- REST API
- MySQL Database

---

## 🗃️ Struktur Database (Contoh)

### 📘 Tabel Mahasiswa
```sql
id, nama, npm, email, password
```

### 📗 Tabel Buku
```sql
id, judul, penulis, isbn, jumlah, foto
```

### 📕 Tabel Peminjaman
```sql
id, id_buku, id_mahasiswa, tanggal_pinjam, tanggal_kembali, status
```

---

## 🚀 Cara Menjalankan Aplikasi

### 🔙 Backend
```bash
cd backend_perpustakaan
python app.py
```

### 📲 Frontend
```bash
cd perpustakaan
flutter pub get
flutter run
```

---

## 📌 Catatan Tambahan

- 📆 Notifikasi pengembalian muncul **3 hari sebelum batas waktu**.
- 📤 Buku yang sudah dikembalikan **tidak tampil** di halaman peminjaman aktif.
- 🔒 **Hanya admin** yang dapat mengelola data buku dan pengguna.
- 
---

## 👥 Kontributor

- 👨‍💻 **Fajar** – Pengembang Utama  
- 🤖 **Leo** – Asisten AI  

---

## 📄 Lisensi

Proyek ini dilisensikan sebagai perangkat lunak tertutup (**Closed Source**).  
Seluruh hak cipta dilindungi. Penggunaan, distribusi, atau modifikasi tanpa izin tertulis **dilarang**.  
📩 Hubungi pengembang untuk izin lebih lanjut.  
[Lihat Lisensi](License)

      
