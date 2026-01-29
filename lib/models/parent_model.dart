import 'user_model.dart';

enum RelationshipType {
  father,
  mother,
  guardian,
}

class ChildProfile {
  final String id;
  final String name;
  final int? age;
  final String? currentGrade;
  final String? schoolName;

  ChildProfile({
    required this.id,
    required this.name,
    this.age,
    this.currentGrade,
    this.schoolName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'currentGrade': currentGrade,
      'schoolName': schoolName,
    };
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      currentGrade: json['currentGrade'] as String?,
      schoolName: json['schoolName'] as String?,
    );
  }
}

class Parent extends User {
  final RelationshipType relationshipType;
  final int numberOfChildren;
  final List<ChildProfile> children;
  final String? address;
  final String? preferredLanguage;

  Parent({
    required super.id,
    required super.fullName,
    required super.email,
    required super.mobileNumber,
    required super.createdAt,
    required this.relationshipType,
    required this.numberOfChildren,
    this.children = const [],
    this.address,
    this.preferredLanguage,
  }) : super(userType: UserType.parent);

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'relationshipType': relationshipType.name,
      'numberOfChildren': numberOfChildren,
      'children': children.map((c) => c.toJson()).toList(),
      'address': address,
      'preferredLanguage': preferredLanguage,
    };
  }

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      mobileNumber: json['mobileNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      relationshipType: RelationshipType.values.firstWhere(
        (e) => e.name == json['relationshipType'],
        orElse: () => RelationshipType.father,
      ),
      numberOfChildren: json['numberOfChildren'] as int,
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => ChildProfile.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      address: json['address'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
    );
  }
}

