import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:secure_application/secure_application.dart';
import '../../core/constants.dart';
import 'package:perpustakaan/core/colors.dart';

class ProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String? foto;
  final String alamat;
  final String noTelp;
  final String npm;

  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.foto,
    required this.alamat,
    required this.noTelp,
    required this.npm,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String imageUrl;

  @override
  void initState() {
    super.initState();
    imageUrl = widget.foto != null && widget.foto!.isNotEmpty
        ? (widget.foto!.startsWith('http')
            ? widget.foto!
            : baseUrl + widget.foto!.replaceAll('\\', '/'))
        : "assets/default_image.png";

    print("Image URL: \$imageUrl");
    print("Foto dari database: \${widget.foto}");
  }

  @override
  Widget build(BuildContext context) {
    String qrData = widget.npm;
    print("🔐 SecureGate aktif di ProfilePage");
    return SecureGate(
      blurr: 10.0,
      lockedBuilder: (context, secureNotifier) => Center(
        child: Text("🔒 Konten ini diamankan"),
      ),
      child: Container(
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
            title: Text('Profile',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.secondary,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: widget.foto != null && widget.foto!.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : AssetImage("assets/default.jpg") as ImageProvider,
                    onBackgroundImageError: (exception, stackTrace) {
                      print("Gagal memuat gambar: \$exception");
                    },
                    child: widget.foto == null || widget.foto!.isEmpty
                        ? Icon(Icons.person, size: 40)
                        : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.email,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Alamat: ${widget.alamat}',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No. Telp: ${widget.noTelp}',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'NPM: ${widget.npm}',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  Text(
                    'QR Code Profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
