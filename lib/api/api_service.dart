import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://72.61.173.20:8080/api';

  // Fetch colleges from API
  static Future<List<Map<String, dynamic>>> fetchColleges() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/colleges'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          final List<dynamic> colleges = jsonData['data'] as List<dynamic>;
          return colleges.map((college) => college as Map<String, dynamic>).toList();
        } else {
          throw Exception('Failed to load colleges: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load colleges: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching colleges: $e');
      rethrow;
    }
  }

  // Fetch schools from API
  static Future<List<Map<String, dynamic>>> fetchSchools() async {
    try {
      print('Fetching schools from: $baseUrl/schools');
      final response = await http.get(
        Uri.parse('$baseUrl/schools'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Schools API response status code: ${response.statusCode}');
      print('Schools API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          final List<dynamic> schools = jsonData['data'] as List<dynamic>;
          print('Successfully loaded ${schools.length} schools');
          return schools.map((school) => school as Map<String, dynamic>).toList();
        } else {
          print('API returned false status: ${jsonData['message']}');
          throw Exception('Failed to load schools: ${jsonData['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load schools: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching schools: $e');
      rethrow;
    }
  }

  // Fetch top colleges from API
  static Future<List<Map<String, dynamic>>> fetchTopColleges() async {
    try {
      print('Fetching top colleges from: $baseUrl/colleges/top');
      final response = await http.get(
        Uri.parse('$baseUrl/colleges/top'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          final List<dynamic> colleges = jsonData['data'] as List<dynamic>;
          print('Successfully loaded ${colleges.length} top colleges');
          return colleges.map((college) => college as Map<String, dynamic>).toList();
        } else {
          print('API returned false status: ${jsonData['message']}');
          throw Exception('Failed to load top colleges: ${jsonData['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load top colleges: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching top colleges: $e');
      rethrow;
    }
  }

  // Filter institutions based on criteria
  // Parameters can include: institution_type, school_type, college_type, gender_type, program_level, curriculum, city, governing_authority, degree_type
  static Future<Map<String, dynamic>> filterInstitutions({
    String? institutionType,
    String? schoolType,
    String? collegeType,
    String? genderType,
    String? programLevel,
    String? curriculum,
    String? city,
    String? governingAuthority,
    String? degreeType,
    int page = 1,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (institutionType != null && institutionType.isNotEmpty) {
        queryParams['institution_type'] = institutionType;
      }
      if (schoolType != null && schoolType.isNotEmpty) {
        queryParams['school_type'] = schoolType;
      }
      if (collegeType != null && collegeType.isNotEmpty) {
        queryParams['college_type'] = collegeType;
      }
      if (genderType != null && genderType.isNotEmpty) {
        queryParams['gender_type'] = genderType;
      }
      if (programLevel != null && programLevel.isNotEmpty) {
        queryParams['program_level'] = programLevel;
      }
      if (curriculum != null && curriculum.isNotEmpty) {
        queryParams['curriculum'] = curriculum;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (governingAuthority != null && governingAuthority.isNotEmpty) {
        queryParams['governing_authority'] = governingAuthority;
      }
      if (degreeType != null && degreeType.isNotEmpty) {
        queryParams['degree_type'] = degreeType;
      }
      queryParams['page'] = page.toString();

      // Build URI with query parameters
      final uri = Uri.parse('$baseUrl/colleges/filterInstitutions')
          .replace(queryParameters: queryParams);

      print('Fetching filtered institutions from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Filter API response status code: ${response.statusCode}');
      print('Filter API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          final data = jsonData['data'] as Map<String, dynamic>;
          final List<dynamic> institutions = data['data'] as List<dynamic>;
          
          print('Successfully loaded ${institutions.length} filtered institutions');
          
          return {
            'institutions': institutions
                .map((inst) => inst as Map<String, dynamic>)
                .toList(),
            'pagination': {
              'current_page': data['current_page'],
              'last_page': data['last_page'],
              'per_page': data['per_page'],
              'total': data['total'],
              'from': data['from'],
              'to': data['to'],
              'next_page_url': data['next_page_url'],
              'prev_page_url': data['prev_page_url'],
            },
            'filters_applied': jsonData['filters_applied'],
          };
        } else {
          print('API returned false status: ${jsonData['message']}');
          throw Exception('Failed to filter institutions: ${jsonData['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to filter institutions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error filtering institutions: $e');
      rethrow;
    }
  }

  // Fetch institution details by ID
  static Future<Map<String, dynamic>> fetchInstitutionDetails(int institutionId) async {
    try {
      print('Fetching institution details from: $baseUrl/colleges/$institutionId');
      final response = await http.get(
        Uri.parse('$baseUrl/colleges/$institutionId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Institution details response status code: ${response.statusCode}');
      print('Institution details response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          print('Successfully loaded institution details');
          // Return the data object directly for easier access
          return {
            'status': true,
            'message': jsonData['message'] as String?,
            'data': jsonData['data'] as Map<String, dynamic>,
          };
        } else {
          print('API returned false status: ${jsonData['message']}');
          throw Exception('Failed to load institution details: ${jsonData['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load institution details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching institution details: $e');
      rethrow;
    }
  }

  // Get institutions where user has applied
  static Future<List<Map<String, dynamic>>> fetchApplications({
    required String token,
  }) async {
    try {
      print('Fetching applications from: $baseUrl/applications');
      final response = await http.get(
        Uri.parse('$baseUrl/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Applications API response status code: ${response.statusCode}');
      print('Applications API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Handle different response formats
        List<dynamic> applications = [];
        
        if (jsonData is Map<String, dynamic>) {
          if (jsonData['status'] == true) {
            // Check for 'data' field first
            if (jsonData['data'] != null) {
              applications = jsonData['data'] as List<dynamic>;
            } 
            // Check for 'applications' field
            else if (jsonData['applications'] != null) {
              applications = jsonData['applications'] as List<dynamic>;
            }
            // Check for direct array response
            else {
              throw Exception('Invalid response format: no data or applications field found');
            }
          } else {
            print('API returned false status: ${jsonData['message']}');
            throw Exception('Failed to load applications: ${jsonData['message'] ?? 'Unknown error'}');
          }
        } else if (jsonData is List) {
          // Direct array response
          applications = jsonData;
        } else {
          throw Exception('Invalid response format');
        }
        
        print('Successfully loaded ${applications.length} applications');
        return applications.map((app) => app as Map<String, dynamic>).toList();
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load applications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching applications: $e');
      rethrow;
    }
  }

  // Check if user has applied to a specific institution and get application ID
  static Future<int?> getApplicationIdForInstitution({
    required int institutionId,
    required String token,
  }) async {
    try {
      // Fetch all applications and find the one for this institution
      final applications = await fetchApplications(token: token);
      
      for (final app in applications) {
        // Check if application has institution object with matching ID
        if (app['institution'] != null) {
          final institution = app['institution'] as Map<String, dynamic>;
          final instId = institution['id'];
          if (instId != null) {
            final id = instId is int ? instId : int.tryParse(instId.toString());
            if (id == institutionId) {
              final appId = app['id'];
              return appId is int ? appId : int.tryParse(appId.toString());
            }
          }
        }
      }
      
      return null; // No application found for this institution
    } catch (e) {
      print('Error checking application for institution: $e');
      return null;
    }
  }

  // Toggle institution wishlist status
  static Future<Map<String, dynamic>> toggleWishlist({
    required int institutionId,
    required String token,
  }) async {
    try {
      print('Toggling wishlist: $baseUrl/wishlist/toggle');
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'institution_id': institutionId,
        }),
      );

      print('Toggle wishlist response status code: ${response.statusCode}');
      print('Toggle wishlist response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to toggle wishlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling wishlist: $e');
      rethrow;
    }
  }

  // Add institution to wishlist (kept for backward compatibility)
  static Future<Map<String, dynamic>> addToWishlist({
    required int institutionId,
    required String token,
  }) async {
    try {
      print('Adding to wishlist: $baseUrl/wishlist/add');
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/add'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'institution_id': institutionId,
        }),
      );

      print('Add wishlist response status code: ${response.statusCode}');
      print('Add wishlist response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to add to wishlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding to wishlist: $e');
      rethrow;
    }
  }

  // Remove institution from wishlist (kept for backward compatibility)
  static Future<Map<String, dynamic>> removeFromWishlist({
    required int institutionId,
    required String token,
  }) async {
    try {
      print('Removing from wishlist: $baseUrl/wishlist/remove/$institutionId');
      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/remove/$institutionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Remove wishlist response status code: ${response.statusCode}');
      print('Remove wishlist response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to remove from wishlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
      rethrow;
    }
  }

  // Get user's wishlist
  static Future<List<Map<String, dynamic>>> getWishlist({
    required String token,
  }) async {
    try {
      print('Fetching wishlist from: $baseUrl/wishlist/');
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Wishlist API response status code: ${response.statusCode}');
      print('Wishlist API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          final List<dynamic> wishlistItems = jsonData['data'] as List<dynamic>;
          print('Successfully loaded ${wishlistItems.length} wishlist items');
          return wishlistItems.map((item) => item as Map<String, dynamic>).toList();
        } else {
          print('API returned false status: ${jsonData['message']}');
          throw Exception('Failed to load wishlist: ${jsonData['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load wishlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching wishlist: $e');
      rethrow;
    }
  }

  // Check if institution is in wishlist
  static Future<bool> checkWishlistStatus({
    required int institutionId,
    required String token,
  }) async {
    try {
      print('Checking wishlist status: $baseUrl/wishlist/check/$institutionId');
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/check/$institutionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Check wishlist response status code: ${response.statusCode}');
      print('Check wishlist response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        // Assuming API returns { "status": true, "data": { "is_in_wishlist": true/false } }
        // or { "status": true, "is_in_wishlist": true/false }
        if (jsonData['status'] == true) {
          if (jsonData['data'] != null && jsonData['data'] is Map) {
            return (jsonData['data'] as Map<String, dynamic>)['is_in_wishlist'] == true;
          } else if (jsonData['is_in_wishlist'] != null) {
            return jsonData['is_in_wishlist'] == true;
          }
        }
        return false;
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error checking wishlist status: $e');
      return false;
    }
  }

  // Fetch application by ID
  static Future<Map<String, dynamic>> fetchApplicationById({
    required int applicationId,
    required String token,
  }) async {
    try {
      print('Fetching application from: $baseUrl/applications/$applicationId');
      final response = await http.get(
        Uri.parse('$baseUrl/applications/$applicationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Application API response status code: ${response.statusCode}');
      print('Application API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          print('Successfully loaded application details');
          return jsonData['data'] as Map<String, dynamic>;
        } else {
          print('API returned false status: ${jsonData['message']}');
          throw Exception('Failed to load application: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load application: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching application: $e');
      rethrow;
    }
  }

  // Update application by ID
  static Future<Map<String, dynamic>> updateApplication({
    required int applicationId,
    required Map<String, dynamic> payload,
    required String token,
  }) async {
    try {
      print('Updating application: $baseUrl/applications/$applicationId');
      final response = await http.put(
        Uri.parse('$baseUrl/applications/$applicationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      print('Update application response status code: ${response.statusCode}');
      print('Update application response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update application: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating application: $e');
      rethrow;
    }
  }

  // Fetch student plans
  static Future<List<Map<String, dynamic>>> fetchStudentPlans() async {
    try {
      print('Fetching student plans from: $baseUrl/student-plans');
      final response = await http.get(
        Uri.parse('$baseUrl/student-plans'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Student plans API response status code: ${response.statusCode}');
      print('Student plans API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          final List<dynamic> plans = jsonData['data'] as List<dynamic>;
          print('Successfully loaded ${plans.length} student plans');
          return plans.map((plan) => plan as Map<String, dynamic>).toList();
        } else {
          print('API returned false status: ${jsonData['message']}');
          throw Exception('Failed to load student plans: ${jsonData['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load student plans: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching student plans: $e');
      rethrow;
    }
  }

  // Create or get conversation with an institution
  static Future<Map<String, dynamic>> createOrGetConversation({
    required int institutionId,
    required String token,
  }) async {
    try {
      print('Creating/getting conversation: $baseUrl/conversations/create');
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'institution_id': institutionId,
        }),
      );

      print('Create conversation response status code: ${response.statusCode}');
      print('Create conversation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          print('Successfully created/retrieved conversation');
          return jsonData['data'] as Map<String, dynamic>;
        } else {
          print('API returned false status: ${jsonData['message']}');
          throw Exception('Failed to create conversation: ${jsonData['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  // Send message via Laravel API
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String message,
    required String senderType,
    required String token,
  }) async {
    try {
      print('Sending message: $baseUrl/conversations/$conversationId/messages');
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message,
          'sender_type': senderType,
        }),
      );

      print('Send message response status code: ${response.statusCode}');
      print('Send message response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}

