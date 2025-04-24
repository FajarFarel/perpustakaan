import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:perpustakaan/penting/constants.dart';
import 'package:perpustakaan/model/book_model.dart'; // Ubah ke model utama

class BookController extends GetxController {
  var dataBuku = <ModelBuku>[].obs;
  File? selectedImage;

  Future<void> fetchDataBuku() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/data_buku'));
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        List<dynamic> data = jsonData['data_buku'];
        dataBuku.value = data.map((item) => ModelBuku.fromJson(item)).toList();
      } else {
        print("❌ Gagal ambil data: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error ambil data: $e");
    }
  }

  void tambahDataBuku(String judul, String penulis, String noBuku,
      String jumlah, String deskripsi, File? foto) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/data_buku'),
      );

      request.fields['judul'] = judul;
      request.fields['penulis'] = penulis;
      request.fields['no_buku'] = noBuku;
      request.fields['jumlah'] = jumlah;
      request.fields['deskripsi'] = deskripsi;

      if (foto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
      }

      var response = await request.send();
      if (response.statusCode == 201) {
        print("✅ Buku ditambahkan");
        fetchDataBuku();
      } else {
        print("❌ Gagal tambah: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error tambah: $e");
    }
  }

  void updateDataBuku(int id, String judul, String penulis, String noBuku,
      String jumlah, String deskripsi, File? foto) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/data_buku/$id'),
      );

      request.fields['judul'] = judul;
      request.fields['penulis'] = penulis;
      request.fields['no_buku'] = noBuku;
      request.fields['jumlah'] = jumlah;
      request.fields['deskripsi'] = deskripsi;

      if (foto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        print("✅ Buku diperbarui");
        fetchDataBuku();
      } else {
        print("❌ Gagal update: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error update: $e");
    }
  }

  void hapusDataBuku(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/data_buku/$id'));
      if (response.statusCode == 200) {
        print("🗑️ Buku dihapus");
        fetchDataBuku();
      } else {
        print("❌ Gagal hapus: ${response.body}");
      }
    } catch (e) {
      print("❌ Error hapus: $e");
    }
  }
}
