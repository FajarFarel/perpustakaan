import 'dart:convert';
import 'dart:io';
import 'package:perpustakaan/core/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perpustakaan/core/constants.dart';

class PengaturanPage extends StatefulWidget {
  @override
  _PengaturanPageState createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController namaController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController alamatController = TextEditingController();
  TextEditingController noTelpController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();

  String npm = "";
  String? fotoUrl;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      setState(() {
        namaController.text = userData['nama'] ?? '';
        emailController.text = userData['email'] ?? '';
        alamatController.text = userData['alamat'] ?? '';
        noTelpController.text = userData['noTelp'] ?? '';
        npm = userData['npm'];
        fotoUrl = userData['foto'];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _simpanPerubahan() async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/update_profile/$npm'),
    );

    request.fields['nama'] = namaController.text;
    request.fields['email'] = emailController.text;
    request.fields['alamat'] = alamatController.text;
    request.fields['noTelp'] = noTelpController.text;
    request.fields['old_password'] = oldPasswordController.text;
    request.fields['new_password'] = newPasswordController.text;

    if (_image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('gambar', _image!.path));
    }

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', responseBody);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Profil berhasil diperbarui, harap login ulang')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal memperbarui profil')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Terjadi kesalahan')),
      );
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
          title: Text('Pengaturan Profil', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.secondary,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : (fotoUrl != null
                                ? (fotoUrl!.startsWith('data:image')
                                    ? MemoryImage(
                                        base64Decode(fotoUrl!.split(',').last))
                                    : NetworkImage(fotoUrl!) as ImageProvider)
                                : AssetImage('assets/default.jpg')
                                    as ImageProvider),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: _pickImage,
                            child: Icon(Icons.edit,
                                size: 20, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.divider, width: 1),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4), 
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField("Nama", namaController),
                        _buildInputField("Alamat", alamatController),
                        _buildInputField("No. Telepon", noTelpController),
                        _buildInputField("Password Lama", oldPasswordController,
                            obscure: true),
                        _buildInputField("Password Baru", newPasswordController,
                            obscure: true),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _simpanPerubahan,
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                    backgroundColor: AppColors.primary,
                    elevation: 4,
                  ),
                  child: Text('Simpan Perubahan',
                      style: TextStyle(color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }
}
