enum UserType {
  parent,
  student,
}

class User {
  final String id;
  final String fullName;
  final String email;
  final String mobileNumber;
  final UserType userType;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.userType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'userType': userType.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      mobileNumber: json['mobileNumber'] as String,
      userType: UserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => UserType.parent,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

