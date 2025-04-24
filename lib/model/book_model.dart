class ModelBuku {
  final int id;
  final String judul;
  final String penulis;
  final String no_buku;
  final int jumlah;
  final String deskripsi;
  final String? fotoBase64;

  ModelBuku({
    required this.id,
    required this.judul,
    required this.penulis,
    required this.no_buku,
    required this.jumlah,
    required this.deskripsi,
    this.fotoBase64,
  });

  factory ModelBuku.fromJson(Map<String, dynamic> json) {
    return ModelBuku(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '-',
      penulis: json['penulis'] ?? '-',
      no_buku: json['no_buku'] ?? '-',
      jumlah: json['jumlah'] ?? 0,
      deskripsi: json['deskripsi'] ?? '-',
      fotoBase64: json['foto'], // ✅ GANTI INI dari 'cover' ke 'foto'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'judul': judul,
      'penulis': penulis,
      'no_buku': no_buku,
      'jumlah': jumlah,
      'deskripsi': deskripsi,
      'cover': fotoBase64,
    };
  }
}
