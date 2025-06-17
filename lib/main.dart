import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:perpustakaan/presentation/pages/splashscreen.dart';
import 'package:get/get.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/pages/admin.dart';
import 'presentation/pages/kelola_pengguna.dart';
import 'presentation/pages/kelola_buku.dart';
import 'presentation/sections/pengaturan.dart';
import 'package:perpustakaan/core/colors.dart';
import 'package:perpustakaan/core/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

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
  request.fields['role'] = 'user';

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
    double angle = 72;

    path.moveTo(centerX, centerY - radius);

    for (int i = 1; i < 5; i++) {
      path.lineTo(
        centerX +
            radius * cos((angle * i - 90) * pi / 180),
        centerY + radius * sin((angle * i - 90) * pi / 180),
      );
    }
    path.close();
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
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality:
            100,
        maxWidth:
            600,
      );
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
    } else if (!RegExp(r'^\d{1,8}$').hasMatch(password)) {
      _showErrorDialog(
          'Password must be up to 8 digits long and contain only numbers');
    } else {
      await registerUserWithImage(
          context, name, alamat, npm, noTelp, email, password, _image!);

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
          backgroundColor: AppColors.secondary,
          title: Text(
            'Register',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        body: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
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
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(children: [
                                TextField(
                                  controller: _nameController,
                                  style: TextStyle(),
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: TextStyle(),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _alamatController,
                                  style: TextStyle(),
                                  decoration: InputDecoration(
                                    labelText: 'Alamat',
                                    labelStyle: TextStyle(),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _npmController,
                                  style: TextStyle(),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'NPM',
                                    labelStyle: TextStyle(),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _noTelpController,
                                  style: TextStyle(),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'No Tlp',
                                    labelStyle: TextStyle(),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _emailController,
                                  style: TextStyle(),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                TextField(
                                  controller: _passwordController,
                                  keyboardType: TextInputType.number,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
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
  String? _currentSSID;
  bool _isWifiBenar = false;

  @override
  void initState() {
    super.initState();
    _cekKoneksiWifi();
    Connectivity().onConnectivityChanged.listen((result) {
      _cekKoneksiWifi();
    });
  }

  Future<void> _cekKoneksiWifi() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final info = NetworkInfo();

    if (connectivityResult == ConnectivityResult.wifi) {
      String? ssid = await info.getWifiName();
      ssid = ssid?.replaceAll('"', '');

      setState(() {
        _currentSSID = ssid;
        _isWifiBenar = ssid == "$wifi";
      });
    } else {
      setState(() {
        _currentSSID = null;
        _isWifiBenar = false;
      });
    }
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

 void _validateAndLogin() async {
  print("🔄 Tombol Login Ditekan!");
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (!email.endsWith('@gmail.com')) {
    _showErrorDialog('Email harus berakhiran @gmail.com');
    return;
  }
  if (!RegExp(r'^\d{1,8}$').hasMatch(password)) {
    _showErrorDialog('Password harus terdiri dari 1-8 digit angka');
    return;
  }

  final connectivity = await Connectivity().checkConnectivity();
  final info = NetworkInfo();

  if (connectivity == ConnectivityResult.wifi) {
    String? ssid = await info.getWifiName();
    ssid = ssid?.replaceAll('"', '');

    if (ssid == "$wifi") {
      print("📶 Terhubung ke Wi-Fi yang diizinkan: $ssid");
      AuthController().loginUser(context, email, password);
    } else {
      print("🚫 Terhubung ke Wi-Fi lain: $ssid");
      _showErrorDialog(
          'Silakan hubungkan perangkat ke Wi-Fi "$wifi" untuk melanjutkan login.');
    }
  } else {
    print("❌ Tidak terhubung ke Wi-Fi mana pun");
    _showErrorDialog(
        'Kamu tidak tersambung ke jaringan Wi-Fi mana pun. Silakan hubungkan ke Wi-Fi "$wifi".');
  }
}

  @override
  Widget build(BuildContext context) {
    debugPrint("📡 Wifi Benar: $_isWifiBenar | SSID: $_currentSSID");
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text('Login', style: TextStyle()),
        backgroundColor: AppColors.secondary,
      ),
      body: Stack(
        children: [
          Container(
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
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Selamat Datang di Perpustakaan Fakultas Kedokteran',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
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
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            style: TextStyle(),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(),
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
                            style: TextStyle(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
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
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RegisterPage()),
                              );
                            },
                            child: Text('Belum punya akun? Daftar',
                                style: TextStyle()),
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
          GetPage(name: '/logout', page: () => LoginPage()),
        ],
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SplashScreen());
  }
}
