import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginApi {
  static const String baseUrl = 'http://72.61.173.20:8080/api';

  /// Login with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// 
  /// Returns a Map containing:
  /// - 'status': bool - Whether the login was successful
  /// - 'message': String - Response message
  /// - 'token': String? - Authentication token (if successful)
  /// - 'user': Map<String, dynamic>? - User data (if successful)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login API response status code: ${response.statusCode}');
      print('Login API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true) {
          // Extract education_type from response (can be at root level or in user.student)
          String? educationType;
          if (jsonData.containsKey('education_type')) {
            educationType = jsonData['education_type'] as String?;
          } else {
            final user = jsonData['user'] as Map<String, dynamic>?;
            if (user != null) {
              final student = user['student'] as Map<String, dynamic>?;
              if (student != null && student.containsKey('education_type')) {
                educationType = student['education_type'] as String?;
              }
            }
          }
          
          return {
            'status': true,
            'message': jsonData['message'] as String? ?? 'Login Successful',
            'token': jsonData['token'] as String?,
            'user': jsonData['user'] as Map<String, dynamic>?,
            'education_type': educationType,
          };
        } else {
          return {
            'status': false,
            'message': jsonData['message'] as String? ?? 'Login failed',
            'token': null,
            'user': null,
            'education_type': null,
          };
        }
      } else {
        // Handle non-200 status codes
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          return {
            'status': false,
            'message': errorData['message'] as String? ?? 'Login failed',
            'token': null,
            'user': null,
          };
        } catch (e) {
          return {
            'status': false,
            'message': 'Login failed: ${response.statusCode}',
            'token': null,
            'user': null,
            'education_type': null,
          };
        }
      }
    } catch (e) {
      print('Error during login: $e');
      return {
        'status': false,
        'message': 'Network error: ${e.toString()}',
        'token': null,
        'user': null,
        'education_type': null,
      };
    }
  }

  /// Check user type after login
  /// 
  /// [token] - Authentication token
  /// 
  /// Returns a Map containing:
  /// - 'status': bool - Whether the request was successful
  /// - 'user_id': int? - User ID
  /// - 'user_type': String? - User type ('parent' or 'student')
  /// - 'is_parent': bool - Whether user is a parent
  /// - 'is_student': bool - Whether user is a student
  /// - 'parent_detail': Map<String, dynamic>? - Parent details if available
  /// - 'student_detail': Map<String, dynamic>? - Student details if available
  static Future<Map<String, dynamic>> checkUserType({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-user-type'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Check user type API response status code: ${response.statusCode}');
      print('Check user type API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true) {
          return {
            'status': true,
            'user_id': jsonData['user_id'] as int?,
            'user_type': jsonData['user_type'] as String?,
            'is_parent': jsonData['is_parent'] as bool? ?? false,
            'is_student': jsonData['is_student'] as bool? ?? false,
            'parent_detail': jsonData['parent_detail'] as Map<String, dynamic>?,
            'student_detail': jsonData['student_detail'] as Map<String, dynamic>?,
          };
        } else {
          return {
            'status': false,
            'message': jsonData['message'] as String? ?? 'Failed to check user type',
            'is_parent': false,
            'is_student': false,
          };
        }
      } else {
        // Handle non-200 status codes
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          return {
            'status': false,
            'message': errorData['message'] as String? ?? 'Failed to check user type',
            'is_parent': false,
            'is_student': false,
          };
        } catch (e) {
          return {
            'status': false,
            'message': 'Failed to check user type: ${response.statusCode}',
            'is_parent': false,
            'is_student': false,
          };
        }
      }
    } catch (e) {
      print('Error checking user type: $e');
      return {
        'status': false,
        'message': 'Network error: ${e.toString()}',
        'is_parent': false,
        'is_student': false,
      };
    }
  }

  /// Register a new user (Parent or Student)
  /// 
  /// Basic fields (required):
  /// [name] - User's full name
  /// [email] - User's email address
  /// [password] - User's password
  /// [type] - User type: "parent" or "student"
  /// 
  /// Parent-specific fields (required if type is "parent"):
  /// [relationshipType] - Relationship type (Father, Mother, Guardian)
  /// [noOfChildren] - Number of children
  /// [address] - Address (optional)
  /// 
  /// Student-specific fields:
  /// [phone] - Phone number (required for student)
  /// [educationType] - Education type: "school" or "college" (required for student)
  /// 
  /// For school (educationType == "school"):
  /// [currentGrade] - Current grade (e.g., "Grade 9")
  /// [gpaOrMarks] - GPA or marks (e.g., "85%")
  /// [address] - Address
  /// 
  /// For college (educationType == "college"):
  /// [institutionName] - Institution name (e.g., "King Saud University")
  /// [courseName] - Course name (e.g., "Computer Science")
  /// [cgpa] - CGPA (e.g., 3.8)
  /// [address] - Address
  /// 
  /// Returns a Map containing:
  /// - 'status': bool - Whether the registration was successful
  /// - 'message': String - Response message
  /// - 'user': Map<String, dynamic>? - User data (if successful)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String type, // "parent" or "student"
    // Parent fields
    String? relationshipType,
    int? noOfChildren,
    String? address,
    // Student fields - common
    String? phone,
    String? educationType, // "school" or "college"
    // Student fields - school
    String? currentGrade,
    String? gpaOrMarks,
    // Student fields - college
    String? institutionName,
    String? courseName,
    double? cgpa,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'type': type,
      };

      // Add parent-specific fields if type is parent
      if (type == 'parent') {
        if (relationshipType != null) {
          payload['relationship_type'] = relationshipType;
        }
        if (noOfChildren != null) {
          payload['no_of_children'] = noOfChildren;
        }
        if (address != null && address.isNotEmpty) {
          payload['address'] = address;
        }
      }

      // Add student-specific fields if type is student
      if (type == 'student') {
        // Common fields
        if (phone != null && phone.isNotEmpty) {
          payload['phone'] = phone;
        }
        if (educationType != null && educationType.isNotEmpty) {
          payload['education_type'] = educationType;
        }
        
        // School-specific fields
        if (educationType == 'school') {
          if (currentGrade != null && currentGrade.isNotEmpty) {
            payload['current_grade'] = currentGrade;
          }
          if (gpaOrMarks != null && gpaOrMarks.isNotEmpty) {
            payload['gpa_or_marks'] = gpaOrMarks;
          }
          if (address != null && address.isNotEmpty) {
            payload['address'] = address;
          }
        }
        
        // College-specific fields
        if (educationType == 'college') {
          if (institutionName != null && institutionName.isNotEmpty) {
            payload['institution_name'] = institutionName;
          }
          if (courseName != null && courseName.isNotEmpty) {
            payload['course_name'] = courseName;
          }
          if (cgpa != null) {
            payload['cgpa'] = cgpa;
          }
          if (address != null && address.isNotEmpty) {
            payload['address'] = address;
          }
        }
      }

      print('=== Registration API Call ===');
      print('URL: $baseUrl/register');
      print('Payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Register API response status code: ${response.statusCode}');
      print('Register API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true) {
          return {
            'status': true,
            'message': jsonData['message'] as String? ?? 'Registration Successful',
            'user': jsonData['user'] as Map<String, dynamic>?,
          };
        } else {
          return {
            'status': false,
            'message': jsonData['message'] as String? ?? 'Registration failed',
            'user': null,
          };
        }
      } else {
        // Handle non-200 status codes
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          return {
            'status': false,
            'message': errorData['message'] as String? ?? 'Registration failed',
            'user': null,
          };
        } catch (e) {
          return {
            'status': false,
            'message': 'Registration failed: ${response.statusCode}',
            'user': null,
          };
        }
      }
    } catch (e) {
      print('Error during registration: $e');
      return {
        'status': false,
        'message': 'Network error: ${e.toString()}',
        'user': null,
      };
    }
  }

  /// Get user profile
  /// 
  /// [token] - Authentication token
  /// 
  /// Returns a Map containing:
  /// - 'status': bool - Whether the request was successful
  /// - 'message': String - Response message
  /// - 'data': Map<String, dynamic>? - Profile data (username, email, type)
  static Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Profile API response status code: ${response.statusCode}');
      print('Profile API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true) {
          return {
            'status': true,
            'message': jsonData['message'] as String? ?? 'Profile retrieved successfully',
            'data': jsonData['data'] as Map<String, dynamic>?,
          };
        } else {
          return {
            'status': false,
            'message': jsonData['message'] as String? ?? 'Failed to retrieve profile',
            'data': null,
          };
        }
      } else {
        // Handle non-200 status codes
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          return {
            'status': false,
            'message': errorData['message'] as String? ?? 'Failed to retrieve profile',
            'data': null,
          };
        } catch (e) {
          return {
            'status': false,
            'message': 'Failed to retrieve profile: ${response.statusCode}',
            'data': null,
          };
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return {
        'status': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }
}

