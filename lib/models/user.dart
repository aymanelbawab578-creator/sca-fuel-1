class User {
  final int id;
  final String username;
  final String fullName;
  final String role;

  User({required this.id, required this.username, required this.fullName, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'Viewer',
    );
  }
}
