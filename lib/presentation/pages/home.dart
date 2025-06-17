import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:perpustakaan/presentation/sections/about.dart';
import 'package:perpustakaan/main.dart';
import 'package:perpustakaan/presentation/pages/profile.dart';
import 'package:perpustakaan/presentation/pages/rent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:perpustakaan/presentation/controllers/book_controller.dart';
import '../../data/models/book_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perpustakaan/presentation/pages/pengaturan_page.dart';
import 'package:perpustakaan/core/colors.dart';
import 'package:perpustakaan/core/constants.dart';

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
  final BookController controller = Get.put(BookController());

  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    controller.fetchDataBuku();
    imageUrl = widget.foto != null && widget.foto!.isNotEmpty
        ? widget.foto!
        : "assets/default_image.png";

    userData = {
      'nama': widget.name,
      'email': widget.email,
      'foto': widget.foto ?? '',
      'alamat': widget.alamat,
      'noTelp': widget.noTelp,
      'npm': widget.npm,
    };

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

  Widget tampilkanFoto(String? foto, {double size = 80}) {
    if (foto == null || foto.isEmpty) {
      print('[tampilkanFoto] Foto kosong atau null.');
      return Icon(Icons.account_circle, size: size, color: Colors.white);
    }

    if (!foto.startsWith('http')) {
      if (foto.contains(',')) {
        foto = foto.split(',').last;
      }
      try {
        final decoded = base64Decode(foto);
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.memory(
            decoded,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        print('Error decoding base64: $e');
        return Icon(Icons.broken_image, size: size);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        foto,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.broken_image, size: size);
        },
      ),
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
                  ? Image.network(
                      '$baseUrl/uploads/buku/${book['cover']}',
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
            AppColors.gradientTop,
            AppColors.gradientBottom,
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
                    style:
                        TextStyle(fontSize: 18, color: AppColors.textPrimary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: _filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = _filteredBooks[index];
                    return Center(
                      child: SizedBox(
                        width: 180,
                        child: GestureDetector(
                          onTap: () => _showBookDetails(context, {
                            'title': book.judul,
                            'author': book.penulis,
                            'no_buku': book.no_buku,
                            'stock': book.jumlah,
                            'cover': book.foto,
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
                                  child: (book.foto != null &&
                                          book.foto!.isNotEmpty)
                                      ? Image.network(
                                          '$baseUrl/uploads/buku/${book.foto}',
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              "assets/placeholder.jpg",
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            );
                                          },
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
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
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
            color: AppColors.secondary,
            borderRadius:
                _isSearching ? BorderRadius.circular(0) : BorderRadius.zero,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
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
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                      style: TextStyle(color: AppColors.textPrimary),
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
              decoration: BoxDecoration(
                color: AppColors.secondary,
              ),
              accountName: Text(widget.name,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400)),
              accountEmail: Text(widget.email,
                  style: TextStyle(color: AppColors.textSecondary)),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      content: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${userData['foto']}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/default.jpg');
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Builder(
                    builder: (_) {
                      try {
                        return tampilkanFoto(userData['foto'], size: 80);
                      } catch (e, stackTrace) {
                        print('Error saat menampilkan foto: $e');
                        print(stackTrace);
                        return Icon(Icons.error, color: Colors.red);
                      }
                    },
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
