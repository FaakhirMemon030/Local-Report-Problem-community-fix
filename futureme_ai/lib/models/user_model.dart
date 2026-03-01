class UserModel {
  final String userId;
  final String name;
  final String email;
  final int age;
  final String profession;
  final double baseSalary;
  final double currentHealthScore;
  final DateTime createdAt;
  final String role;
  final bool isPremium;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.age,
    required this.profession,
    required this.baseSalary,
    required this.currentHealthScore,
    required this.createdAt,
    this.role = 'user',
    this.isPremium = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'age': age,
      'profession': profession,
      'baseSalary': baseSalary,
      'currentHealthScore': currentHealthScore,
      'createdAt': createdAt.toIso8601String(),
      'role': role,
      'isPremium': isPremium,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 0,
      profession: map['profession'] ?? '',
      baseSalary: (map['baseSalary'] ?? 0).toDouble(),
      currentHealthScore: (map['currentHealthScore'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      role: map['role'] ?? 'user',
      isPremium: map['isPremium'] ?? false,
    );
  }
}
