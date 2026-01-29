import 'user_model.dart';

enum Gender {
  male,
  female,
  other,
}

enum AcademicBoard {
  saudi,
  cbse,
  ib,
  igcse,
  other,
}

enum PreferredStream {
  science,
  commerce,
  arts,
  other,
}

class Student extends User {
  final DateTime dateOfBirth;
  final Gender gender;
  final String currentGrade;
  final String? currentSchool;
  final AcademicBoard? academicBoard;
  final double? gpa;
  final PreferredStream? preferredStream;
  final String? address;

  Student({
    required super.id,
    required super.fullName,
    required super.email,
    required super.mobileNumber,
    required super.createdAt,
    required this.dateOfBirth,
    required this.gender,
    required this.currentGrade,
    this.currentSchool,
    this.academicBoard,
    this.gpa,
    this.preferredStream,
    this.address,
  }) : super(userType: UserType.student);

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender.name,
      'currentGrade': currentGrade,
      'currentSchool': currentSchool,
      'academicBoard': academicBoard?.name,
      'gpa': gpa,
      'preferredStream': preferredStream?.name,
      'address': address,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      mobileNumber: json['mobileNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.male,
      ),
      currentGrade: json['currentGrade'] as String,
      currentSchool: json['currentSchool'] as String?,
      academicBoard: json['academicBoard'] != null
          ? AcademicBoard.values.firstWhere(
              (e) => e.name == json['academicBoard'],
              orElse: () => AcademicBoard.other,
            )
          : null,
      gpa: json['gpa'] != null ? (json['gpa'] as num).toDouble() : null,
      preferredStream: json['preferredStream'] != null
          ? PreferredStream.values.firstWhere(
              (e) => e.name == json['preferredStream'],
              orElse: () => PreferredStream.other,
            )
          : null,
      address: json['address'] as String?,
    );
  }
}

