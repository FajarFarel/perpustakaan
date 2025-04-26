import 'package:flutter/material.dart';
import 'package:perpustakaan/penting/about.dart';
import 'package:perpustakaan/main.dart';
import 'package:perpustakaan/model/profile.dart';
import 'package:perpustakaan/model/rent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../controller/book_controller.dart';
import '../model/book_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perpustakaan/model/pengaturan_page.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String email;
  final String? foto;
  final String alamat;
  final String noTelp;
  final String npm;

  const HomePage({
    super.key,
    required this.name,
    required this.email,
    required this.foto,
    required this.alamat,
    required this.noTelp,
    required this.npm,
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final BookController bookController = Get.put(BookController());
  late List<ModelBuku> _filteredBooks = [];
  late String imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    imageUrl = widget.foto != null && widget.foto!.isNotEmpty
        ? widget.foto!
        : "assets/default_image.png";

    bookController.fetchDataBuku().then((_) {
      setState(() {
        _filteredBooks = List.from(bookController.dataBuku);
        _isLoading = false;
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _showBookDetails(BuildContext context, Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(book['title']!,
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              book['cover'] != null && book['cover'].toString().isNotEmpty
                  ? Image.memory(
                      base64Decode(book['cover'].split(',').last),
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/placeholder.jpg',
                            height: 150, fit: BoxFit.cover);
                      },
                    )
                  : Image.asset('assets/placeholder.jpg',
                      height: 150, fit: BoxFit.cover),
              SizedBox(height: 10),
              Text('Penulis: ${book['author']}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('No_Buku: ${book['no_buku']}',
                  style: TextStyle(color: Colors.grey)),
              Text('Jumlah: ${book['stock']}',
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 10),
              Text(book['description'] ?? '')
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget buildBookshelf() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(2, 163, 163, 100),
            Color.fromRGBO(6, 136, 136, 1)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredBooks.isEmpty
              ? Center(
                  child: Text(
                    "Book not found",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, // batas maksimal lebar setiap item
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: _filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = _filteredBooks[index];
                    return Center(
                      child: SizedBox(
                        width: 180, // Atur ukuran tetap kartu, ini kuncinya
                        child: GestureDetector(
                          onTap: () => _showBookDetails(context, {
                            'title': book.judul,
                            'author': book.penulis,
                            'no_buku': book.no_buku,
                            'stock': book.jumlah,
                            'cover': book.fotoBase64,
                            'description': book.deskripsi,
                          }),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12.0)),
                                  child: book.fotoBase64 != null &&
                                          book.fotoBase64!.isNotEmpty
                                      ? Image.memory(
                                          base64Decode(
                                              book.fotoBase64!.split(',').last),
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          "assets/placeholder.jpg",
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    book.judul,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
    );
  }

  void _searchBook(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBooks = List.from(bookController.dataBuku);
      } else {
        _filteredBooks = bookController.dataBuku
            .where((book) =>
                book.judul.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Color.fromRGBO(2, 163, 163, 100),
            borderRadius:
                _isSearching ? BorderRadius.circular(0) : BorderRadius.zero,
          ),
          child: AppBar(
            iconTheme: IconThemeData(color: const Color.fromARGB(255, 0, 0, 0)),
            backgroundColor: Colors.transparent,
            title: AnimatedSwitcher(
              duration: Duration(milliseconds: 1000),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isSearching
                  ? TextField(
                      key: ValueKey(1),
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _searchBook,
                      decoration: InputDecoration(
                        hintText: "Search books...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                      style: TextStyle(color: Colors.white),
                    )
                  : Text(
                      'Welcome, ${widget.name}',
                      key: ValueKey(2),
                      style:
                          TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search,
                    color: const Color.fromARGB(255, 0, 0, 0)),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _searchBook('');
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
      body: buildBookshelf(),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.name),
              accountEmail: Text(widget.email),
              currentAccountPicture: CircleAvatar(
                backgroundImage: widget.foto != null && widget.foto!.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const AssetImage("assets/default.jpg")
                        as ImageProvider,
                onBackgroundImageError: (exception, stackTrace) {
                  print("Gagal memuat gambar: $exception");
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    name: widget.name,
                    email: widget.email,
                    foto: widget.foto,
                    alamat: widget.alamat,
                    noTelp: widget.noTelp,
                    npm: widget.npm,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.library_books),
              title: Text('Rent Books'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookScreen(),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    name: widget.name,
                    email: widget.email,
                    foto: widget.foto,
                    alamat: widget.alamat,
                    noTelp: widget.noTelp,
                    npm: widget.npm,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Pengaturan"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PengaturanPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text("About"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
            Spacer(),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help'),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      title: Text('Pilih kontak tujuan'),
                      children: <Widget>[
                        SimpleDialogOption(
                          onPressed: () async {
                            Navigator.pop(context);
                            final url =
                                Uri.parse('https://wa.me/6287758568886');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Text('WhatsApp Admin'),
                        ),
                        SimpleDialogOption(
                          onPressed: () async {
                            Navigator.pop(context);
                            final url = Uri.parse(
                                'https://www.instagram.com/andhikakaa09');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Text('Instagram Admin'),
                        ),
                        SimpleDialogOption(
                          onPressed: () async {
                            Navigator.pop(context);
                            final emailUri = Uri.parse(
                                'mailto:farelparjo@gmail.com?subject=Butuh%20Bantuan&body=Halo%20Admin%2C%20saya%20ingin%20bertanya...');
                            if (await canLaunchUrl(emailUri)) {
                              await launchUrl(
                                emailUri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              throw 'Tidak bisa membuka aplikasi email';
                            }
                          },
                          child: Text('Email Admin'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
