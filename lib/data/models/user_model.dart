class User {
  final String id;
  final String nama;
  final String email;
  final String role;
  final String alamat;

  User({required this.id, required this.nama, required this.email, required this.role, required this.alamat});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      role: json['role'],
      alamat: json['alamat'],
    );
  }
}
