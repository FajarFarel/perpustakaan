import 'package:flutter/material.dart';
import 'package:perpustakaan/core/colors.dart';

class nyoba extends StatefulWidget {
  const nyoba({super.key});

  @override
  State<nyoba> createState() => _nyobaState();
}

class _nyobaState extends State<nyoba> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle()),
        backgroundColor: AppColors.secondary,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 16,
            child: Row(
              children: [
                Icon(
                  Icons.wifi,
                  size: 28,
                  color: Colors.black,
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Text(
                    'Perpustakaan_WiFi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}