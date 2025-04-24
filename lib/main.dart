import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:perpustakaan/penting/splashscreen.dart';
import 'package:get/get.dart';
import 'controller/auth_controller.dart';
import 'model/admin.dart';
import 'controller/kelola_pengguna.dart';
import 'model/kelola_buku.dart';
import 'penting/pengaturan.dart';
import 'penting/laporan.dart';
import 'package:perpustakaan/penting/constants.dart';

Future<void> registerUserWithImage(
  BuildContext context,
  String nama,
  String alamat,
  String npm,
  String noTelp,
  String email,
  String password,
  File foto,
) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/register'),
  );

  request.fields['nama'] = nama;
  request.fields['alamat'] = alamat;
  request.fields['npm'] = npm;
  request.fields['noTelp'] = noTelp;
  request.fields['email'] = email;
  request.fields['password'] = password;
  request.fields['role'] = 'user'; // role otomatis user

  request.files.add(await http.MultipartFile.fromPath('gambar', foto.path));

  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var responseData = jsonDecode(responseBody);

    if (response.statusCode == 201) {
      print("✅ Register Berhasil!");
      print("User Data: $responseData");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Redirecting to login...'),
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
    } else {
      // Tampilkan error dari backend
      String errorMsg = responseData['error'] ?? 'Gagal melakukan registrasi';
      print("❌ Gagal Register: $errorMsg");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Gagal Register: $errorMsg")),
      );
    }
  } catch (e) {
    print("❌ Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error: $e")),
    );
  }
}

class PentagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double radius = size.width / 1;

    double angle = 72; // Angle between points

    // Start from the top middle point
    path.moveTo(centerX, centerY - radius);

    // Create the 5 corners of the pentagon
    for (int i = 1; i < 5; i++) {
      path.lineTo(
        centerX +
            radius * cos((angle * i - 90) * pi / 180), // Adjust for rotation
        centerY + radius * sin((angle * i - 90) * pi / 180),
      );
    }

    path.close(); // Close the path to form the pentagon

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _npmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  File? _image;
  bool _obscurePassword = true;
  bool _isDarkMode = false;

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  final ImagePicker _picker = ImagePicker();

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Gagal mengambil foto: $e');
    }
  }

  void _validateAndRegister() async {
    final name = _nameController.text.trim();
    final alamat = _alamatController.text.trim();
    final npm = _npmController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final noTelp = _noTelpController.text.trim();

    if (_image == null) {
      _showErrorDialog('Image cannot be empty');
    } else if (name.isEmpty) {
      _showErrorDialog('Name cannot be empty');
    } else if (alamat.isEmpty) {
      _showErrorDialog('Alamat cannot be empty');
    } else if (npm.isEmpty || !RegExp(r'^\d+$').hasMatch(npm)) {
      _showErrorDialog('NPM hanya boleh berisi angka');
    } else if (noTelp.isEmpty || !RegExp(r'^\d{1,12}$').hasMatch(noTelp)) {
      _showErrorDialog(
          'Number must be up to 12 digits long and contain only numbers');
    } else if (email.isEmpty || !email.endsWith('@gmail.com')) {
      _showErrorDialog('Email must end with @gmail.com');
    } else if (!RegExp(r'^\d{1,6}$').hasMatch(password)) {
      _showErrorDialog(
          'Password must be up to 8 digits long and contain only numbers');
    } else {
      // ✅ Kirim data ke backend
      await registerUserWithImage(
          context, name, alamat, npm, noTelp, email, password, _image!);

      // ✅ Tampilkan notifikasi & pindah ke halaman login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Registration successful! Redirecting to login...')),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Register',style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the color of the back button
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: _toggleDarkMode,
            ),
          ],
        ),
        body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode
                    ? [Colors.black, Colors.grey[900]!]
                    : [Colors.blue[200]!, Colors.blue[800]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'Create Your Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    _isDarkMode ? Colors.white : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipPath(
                                clipper: PentagonClipper(),
                                child: Image.asset(
                                  'assets/logofk.png',
                                  height: 127,
                                  width: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 20),
                              GestureDetector(
                                onTap: () async {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.camera),
                                            title: Text('Take a Photo'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImage(ImageSource.camera);
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.photo_library),
                                            title: Text('Choose from Gallery'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImage(ImageSource.gallery);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: _image != null
                                    ? CircleAvatar(
                                        radius: 50,
                                        backgroundImage: FileImage(_image!),
                                      )
                                    : CircleAvatar(
                                        radius: 50,
                                        child: Icon(Icons.camera_alt, size: 40),
                                      ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(children: [
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _alamatController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Alamat',
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _npmController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'NPM',
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _noTelpController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'No Tlp',
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _passwordController,
                                  keyboardType: TextInputType.number,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.0),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 50, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _validateAndRegister,
                                  child: Text(
                                    'Register',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ]))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )));
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isDarkMode = false;

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _validateAndLogin() {
    print("🔄 Tombol Login Ditekan!");
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!email.endsWith('@gmail.com')) {
      _showErrorDialog('Email harus berakhiran @gmail.com');
    } else if (!RegExp(r'^\d{1,8}$').hasMatch(password)) {
      _showErrorDialog('Password harus terdiri dari 1-8 digit angka');
    } else {
      print("🔄 Memanggil loginUser...");
      AuthController().loginUser(context, email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: _toggleDarkMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode
                    ? [Colors.black, Colors.grey[900]!]
                    : [Colors.blue[200]!, Colors.blue[800]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Selamat Datang di Perpustakaan Fakultas Kedokteran',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Logo
                    ClipPath(
                      clipper: PentagonClipper(),
                      child: Image.asset(
                        'assets/logofk.png',
                        height: 157,
                        width: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Input Fields
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            keyboardType: TextInputType.number,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Login Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _validateAndLogin,
                            child: const Text('Login',
                                style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 10),
                          // Register Button
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RegisterPage()),
                              );
                            },
                            child: const Text('Belum punya akun? Daftar',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Perpustakaan Online',
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => AdminHomePage()),
          GetPage(name: '/kelolaPengguna', page: () => KelolaPengguna()),
          GetPage(name: '/kelolaBuku', page: () => KelolaBuku()),
          GetPage(name: '/pengaturan', page: () => Pengaturan()),
          GetPage(name: '/laporan', page: () => Laporan()),
          GetPage(name: '/logout', page: () => LoginPage()),
        ],
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SplashScreen());
  }
}
