import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/parent_model.dart';
import '../models/student_model.dart';
import '../api/login_api.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _usersKey = 'all_users';
  static const String _tokenKey = 'auth_token';
  static const String _educationTypeKey = 'education_type';

  // Static OTP for testing (OTP login still uses mock)
  static const String _validOTP = '1234';

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    final userData = json.decode(userJson) as Map<String, dynamic>;
    final userType = UserType.values.firstWhere(
      (e) => e.name == userData['userType'],
      orElse: () => UserType.parent,
    );

    if (userType == UserType.parent) {
      return Parent.fromJson(userData);
    } else {
      return Student.fromJson(userData);
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      // Call the login API
      final result = await LoginApi.login(
        email: email,
        password: password,
      );

      if (result['status'] == true) {
        // Store the authentication token
        final token = result['token'] as String?;
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(_tokenKey, token);
        }

        // Store education_type if available
        final educationType = result['education_type'] as String?;
        if (educationType != null) {
          await prefs.setString(_educationTypeKey, educationType);
        }

        // Map API user response to local User model
        final apiUser = result['user'] as Map<String, dynamic>?;
        if (apiUser != null) {
          // Convert API user format to local User model
          // API returns: id, name, email, type, created_at
          // Local User model needs: id, fullName, email, mobileNumber, userType, createdAt
          final user = Parent(
            id: apiUser['id'].toString(),
            fullName: apiUser['name'] as String? ?? email,
            email: apiUser['email'] as String? ?? email,
            mobileNumber: '', // API doesn't return mobile, set empty or get from elsewhere
            createdAt: apiUser['created_at'] != null
                ? DateTime.parse(apiUser['created_at'] as String)
                : DateTime.now(),
            relationshipType: RelationshipType.father, // Default value
            numberOfChildren: 1, // Default value
          );

          await _setCurrentUser(user);
          await _saveUser(user);

          return {
            'success': true,
            'user': user,
            'message': result['message'] as String? ?? 'Login successful',
            'education_type': educationType,
          };
        } else {
          return {
            'success': false,
            'message': 'User data not received from server',
          };
        }
      } else {
        return {
          'success': false,
          'message': result['message'] as String? ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Error in loginWithEmail: $e');
      return {
        'success': false,
        'message': 'An error occurred during login. Please try again.',
      };
    }
  }

  // Get authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get education type
  Future<String?> getEducationType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_educationTypeKey);
  }

  // Send OTP (mock - always returns success)
  Future<Map<String, dynamic>> sendOTP(String mobileNumber) async {
    // Validate mobile number
    if (!_isValidMobileNumber(mobileNumber)) {
      return {
        'success': false,
        'message': 'Invalid mobile number.',
      };
    }

    // In real app, this would call backend API
    // For now, just return success
    return {
      'success': true,
      'message': 'OTP sent to $mobileNumber',
      'otp': _validOTP, // For testing purposes
    };
  }

  // Verify OTP and login/register
  Future<Map<String, dynamic>> verifyOTP(
    String mobileNumber,
    String otp,
  ) async {
    // Validate OTP
    if (otp != _validOTP) {
      return {
        'success': false,
        'message': 'Invalid OTP. Please try again.',
      };
    }

    // Check if user exists with this mobile number
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    User? user;

    if (usersJson != null) {
      final usersList = json.decode(usersJson) as List<dynamic>;
      final userData = usersList.firstWhere(
        (u) => (u as Map<String, dynamic>)['mobileNumber'] == mobileNumber,
        orElse: () => null,
      );

      if (userData != null) {
        final userType = UserType.values.firstWhere(
          (e) => e.name == (userData as Map<String, dynamic>)['userType'],
          orElse: () => UserType.parent,
        );
        if (userType == UserType.parent) {
          user = Parent.fromJson(userData as Map<String, dynamic>);
        } else {
          user = Student.fromJson(userData as Map<String, dynamic>);
        }
      }
    }

    // If user doesn't exist, we'll need registration data
    // For now, return success and let registration handle user creation
    if (user != null) {
      await _setCurrentUser(user);
      return {
        'success': true,
        'user': user,
        'isNewUser': false,
      };
    }

    return {
      'success': true,
      'isNewUser': true,
      'mobileNumber': mobileNumber,
    };
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String mobileNumber,
    required UserType userType,
    // Parent specific
    RelationshipType? relationshipType,
    int? numberOfChildren,
    String? address,
    String? preferredLanguage,
    // Student specific
    DateTime? dateOfBirth,
    Gender? gender,
    String? currentGrade,
    String? currentSchool,
    AcademicBoard? academicBoard,
    double? gpa,
    PreferredStream? preferredStream,
  }) async {
    // Validate inputs
    if (!_isValidEmail(email)) {
      return {
        'success': false,
        'message': 'Invalid email format',
      };
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    if (!_isValidMobileNumber(mobileNumber)) {
      return {
        'success': false,
        'message': 'Invalid mobile number.',
      };
    }

    // Check if email or mobile already exists
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final usersList = json.decode(usersJson) as List<dynamic>;
      final emailExists = usersList.any(
        (u) => (u as Map<String, dynamic>)['email'] == email,
      );
      final mobileExists = usersList.any(
        (u) => (u as Map<String, dynamic>)['mobileNumber'] == mobileNumber,
      );

      if (emailExists) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }

      if (mobileExists) {
        return {
          'success': false,
          'message': 'Mobile number already registered',
        };
      }
    }

    // Create user based on type
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    User user;

    if (userType == UserType.parent) {
      if (relationshipType == null || numberOfChildren == null) {
        return {
          'success': false,
          'message': 'Missing required parent fields',
        };
      }

      user = Parent(
        id: userId,
        fullName: fullName,
        email: email,
        mobileNumber: mobileNumber,
        createdAt: DateTime.now(),
        relationshipType: relationshipType,
        numberOfChildren: numberOfChildren,
        address: address,
        preferredLanguage: preferredLanguage,
      );
    } else {
      if (dateOfBirth == null || gender == null || currentGrade == null) {
        return {
          'success': false,
          'message': 'Missing required student fields',
        };
      }

      user = Student(
        id: userId,
        fullName: fullName,
        email: email,
        mobileNumber: mobileNumber,
        createdAt: DateTime.now(),
        dateOfBirth: dateOfBirth,
        gender: gender,
        currentGrade: currentGrade,
        currentSchool: currentSchool,
        academicBoard: academicBoard,
        gpa: gpa,
        preferredStream: preferredStream,
        address: address,
      );
    }

    await _saveUser(user);
    await _setCurrentUser(user);

    return {
      'success': true,
      'user': user,
    };
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_educationTypeKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Helper methods
  Future<void> _setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    List<dynamic> usersList = [];

    if (usersJson != null) {
      usersList = json.decode(usersJson) as List<dynamic>;
    }

    // Check if user already exists and update, otherwise add
    final index = usersList.indexWhere(
      (u) => (u as Map<String, dynamic>)['id'] == user.id,
    );

    if (index >= 0) {
      usersList[index] = user.toJson();
    } else {
      usersList.add(user.toJson());
    }

    await prefs.setString(_usersKey, json.encode(usersList));
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool _isValidMobileNumber(String mobile) {
    // Basic validation - just check if it's not empty and contains digits
    // Country-specific length validation is handled by the form
    final digitsOnly = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.isNotEmpty && digitsOnly.length >= 8 && digitsOnly.length <= 15;
  }
}

