class UserData {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final DateTime createdAt;

  UserData({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'Viewer',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}

class SettingsData {
  final int totalVehicles;
  final DateTime lastSyncTime;

  SettingsData({
    required this.totalVehicles,
    required this.lastSyncTime,
  });
}

class SettingsValidation {
  static String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'اسم المستخدم لا يمكن أن يكون فارغاً';
    }
    if (username.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'كلمة المرور لا يمكن أن تكون فارغة';
    }
    if (password.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    return null;
  }

  static String? validatePasswordMatch(String password, String confirmPassword) {
    if (password != confirmPassword) {
      return 'كلمات المرور غير متطابقة';
    }
    return null;
  }

  static String? validateNewPasswordDifferent(String oldPassword, String newPassword) {
    if (oldPassword == newPassword) {
      return 'كلمة المرور الجديدة يجب أن تختلف عن القديمة';
    }
    return null;
  }
}
