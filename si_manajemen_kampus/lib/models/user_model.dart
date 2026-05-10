enum UserRole { pimpinan, admin, user }

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? profilePhoto;
  final String? department;
  final String? position;
  final String? nik;
  final String? jabatan;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.profilePhoto,
    this.department,
    this.position,
    this.nik,
    this.jabatan,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      nik: json['nik'] as String?,
      jabatan: json['jabatan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'profilePhoto': profilePhoto,
      'department': department,
      'position': position,
      'nik': nik,
      'jabatan': jabatan,
    };
  }

  // Helper method to check if user is admin
  bool get isAdmin => role == 'admin';

  // Helper method to check if user is pimpinan
  bool get isPimpinan => role == 'pimpinan';

  // Helper method to check if user is regular user
  bool get isRegularUser => role == 'user';

  // Helper method to check if user has leadership role
  bool get hasLeadershipRole => role == 'admin' || role == 'pimpinan';
}
