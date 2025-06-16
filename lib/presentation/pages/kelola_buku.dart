import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:perpustakaan/presentation/controllers/book_controller.dart';
import 'package:perpustakaan/data/models/book_model.dart';
import 'package:perpustakaan/core/constants.dart'; 

class KelolaBuku extends StatefulWidget {
  const KelolaBuku({super.key});

  @override
  State<KelolaBuku> createState() => _KelolaBukuState();
}

// Tambahkan di atas class
TextEditingController judulController = TextEditingController();
TextEditingController penulisController = TextEditingController();
TextEditingController noBukuController = TextEditingController();
TextEditingController jumlahController = TextEditingController();
TextEditingController deskripsiController = TextEditingController();

File? selectedImage;

class _KelolaBukuState extends State<KelolaBuku> {
  final BookController bookController = Get.put(BookController());
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    bookController.fetchDataBuku();
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Ambil Foto"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Pilih dari Galeri"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengakses kamera: $e");
    }
  }

void _showForm({ModelBuku? buku}) {
  // Isi data jika mode edit
  if (buku != null) {
    judulController.text = buku.judul;
    penulisController.text = buku.penulis;
    noBukuController.text = buku.no_buku;
    jumlahController.text = buku.jumlah.toString();
    deskripsiController.text = buku.deskripsi;
    selectedImage = null; // Atur sesuai logic kamu kalau ingin preview gambar lama
  } else {
    judulController.clear();
    penulisController.clear();
    noBukuController.clear();
    jumlahController.clear();
    deskripsiController.clear();
    selectedImage = null;
  }

  Future<void> pickImage(ImageSource source, void Function(void Function()) updateState) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        updateState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil gambar: $e");
    }
  }

  Get.dialog(
    AlertDialog(
      title: Text(buku == null ? 'Tambah Buku' : 'Edit Buku'),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judulController,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextField(
                controller: penulisController,
                decoration: const InputDecoration(labelText: 'Penulis'),
              ),
              TextField(
                controller: noBukuController,
                decoration: const InputDecoration(labelText: 'No Buku'),
              ),
              TextField(
                controller: jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah'),
              ),
              TextField(
                controller: deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 10),
              selectedImage != null
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        selectedImage!,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Text("Belum ada gambar"),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text("Ambil Foto"),
                          onTap: () {
                            Navigator.pop(context);
                            pickImage(ImageSource.camera, setState);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text("Pilih dari Galeri"),
                          onTap: () {
                            Navigator.pop(context);
                            pickImage(ImageSource.gallery, setState);
                          },
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.image),
                label: const Text("Pilih Gambar"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () {
            if (judulController.text.isEmpty ||
                penulisController.text.isEmpty ||
                noBukuController.text.isEmpty ||
                jumlahController.text.isEmpty ||
                deskripsiController.text.isEmpty) {
              Get.snackbar("Error", "Semua field wajib diisi",
                  backgroundColor: Colors.redAccent, colorText: Colors.white);
              return;
            }

            if (int.tryParse(jumlahController.text) == null ||
                int.parse(jumlahController.text) <= 0) {
              Get.snackbar("Error", "Jumlah harus angka dan lebih dari 0",
                  backgroundColor: Colors.redAccent, colorText: Colors.white);
              return;
            }

            if (buku == null) {
              bookController.tambahDataBuku(
                judulController.text,
                penulisController.text,
                noBukuController.text,
                jumlahController.text,
                deskripsiController.text,
                selectedImage,
              );
            } else {
              bookController.updateDataBuku(
                buku.id,
                judulController.text,
                penulisController.text,
                noBukuController.text,
                jumlahController.text,
                deskripsiController.text,
                selectedImage,
              );
            }

            Get.back();
          },
          child: Text(buku == null ? "Simpan" : "Update"),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Buku')),
      body: Obx(() {
        final books = bookController.dataBuku;
        if (books.isEmpty) return const Center(child: Text("Belum ada buku"));

        return Container(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final buku = books[index];
              return GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(buku.judul,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                              const SizedBox(height: 10),
                              Center(
                                child: SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: buku.foto != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            '$baseUrl/uploads/buku/${buku.foto}',
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                    Icons.broken_image,
                                                    size: 60),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.book,
                                              size: 60),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text("Penulis: ${buku.penulis}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text("No Buku: ${buku.no_buku}",
                                  style:
                                      TextStyle(color: Colors.grey[600])),
                              Text("Stok: ${buku.jumlah}",
                                  style:
                                      TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 15),
                              Text(buku.deskripsi,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Tutup"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 150,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: buku.foto != null
                              ? Image.network(
                                  '$baseUrl/uploads/buku/${buku.foto}',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.book, size: 60),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            buku.judul,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => _showForm(buku: buku),
                            icon: const Icon(Icons.edit, color: Colors.orange),
                          ),
                          IconButton(
                            onPressed: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                bookController.hapusDataBuku(buku.id);
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}