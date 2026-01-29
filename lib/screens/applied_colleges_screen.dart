import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../api/api_service.dart';
import '../services/auth_service.dart';
import 'institution_details_screen.dart';
import 'search_screen.dart';
import 'application_form_screen.dart';

enum InstitutionType {
  schools,
  colleges,
}

enum ApplicationStatus {
  applied,
  inReview,
  accepted,
}

class AppliedCollegesScreen extends StatefulWidget {
  const AppliedCollegesScreen({super.key});

  @override
  State<AppliedCollegesScreen> createState() => _AppliedCollegesScreenState();
}

class _AppliedCollegesScreenState extends State<AppliedCollegesScreen> {
  final AuthService _authService = AuthService();
  
  // API data
  List<Map<String, dynamic>> _appliedInstitutions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load applications when screen is initialized
    _loadApplications();
  }

  // Method to refresh data (can be called when needed)
  Future<void> refreshApplications() async {
    await _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view your applications';
        });
        return;
      }

      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token not found';
        });
        return;
      }

      final applications = await ApiService.fetchApplications(token: token);
      
      print('=== APPLICATIONS DATA ===');
      print('Total applications from API: ${applications.length}');
      
      // Transform API response to match expected format
      final List<Map<String, dynamic>> transformedList = [];
      
      for (final app in applications) {
        // The API returns application data with nested institution object
        final institution = app['institution'] as Map<String, dynamic>?;
        
        if (institution == null) {
          print('Warning: Institution data is null for application ${app['id']}');
          continue;
        }
        
        // Extract institution data and merge with application-specific data
        final transformedData = {
          ...institution,
          // Keep application-specific fields
          'application_id': app['id'],
          'student_name': app['student_name'] as String?,
          'arabic_name': app['arabic_name'] as String?,
          'program_course': app['program_course'] as String?,
          'course': app['course'] as String?,
          'department': app['department'] as String?,
          'status': _getStatusString(app['status']),
          'institution_type': app['institution_type'] as String? ?? institution['institution_type'] as String?,
          'appliedDate': app['created_at'] != null 
              ? _parseDateTime(app['created_at'] as String)
              : DateTime.now(),
        };
        
        transformedList.add(transformedData);
        final institutionName = institution['name'] ?? institution['institution_name'] ?? 'Unknown';
        print('Added application: $institutionName (Application ID: ${app['id']})');
      }
      
      // Show ALL applications (don't remove duplicates)
      _appliedInstitutions = transformedList;
      
      // Sort by applied date (most recent first)
      _appliedInstitutions.sort((a, b) {
        final dateA = a['appliedDate'] as DateTime;
        final dateB = b['appliedDate'] as DateTime;
        return dateB.compareTo(dateA);
      });
      
      print('Total applications to display: ${_appliedInstitutions.length}');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading applications: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load applications. Please try again.';
      });
    }
  }

  // Removed sample data - now using API
  /*
  {
    'name': 'Al-Faisal International School',
    'type': InstitutionType.schools,
    'logo': 'assets/images/Al-Faisal International School.avif',
    'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
    'distance': 3.1,
    'rating': 4.3,
    'reviews': 156,
    'gradeLevel': 'primary',
    'genderType': 'co_education',
    'schoolType': 'private',
    'city': 'riyadh',
    'institutionType': 'Private',
    'gender_type': 'Co-Education',
    'curriculum': ['American'],
    'education_levels': ['Kindergarten', 'Primary', 'Intermediate', 'Secondary'],
    'accreditation': ['MOE Saudi', 'Cognia'],
    'fees': {'min': 25000, 'max': 45000, 'currency': 'SAR'},
    'facilities': ['Science Labs', 'Library', 'Sports Complex', 'Computer Lab', 'Art Room', 'Music Room'],
    'transportation': true,
    'capacity': 1200,
    'contact': {
      'phone': '+966114567890',
      'email': 'info@alfaisal.edu.sa',
      'website': 'https://alfaisal.edu.sa'
    },
    'location': {
      'city': 'Riyadh',
      'area': 'Al Olaya',
      'latitude': 24.7136,
      'longitude': 46.6753
    },
    'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records', 'Health Certificate'],
    'status': ApplicationStatus.applied,
    'appliedDate': DateTime.now().subtract(const Duration(days: 5)),
  },
  {
    'name': 'Riyadh Schools',
    'type': InstitutionType.schools,
    'logo': 'assets/images/Riyadh Schools.png',
    'description': 'Prestigious private school offering American curriculum with focus on holistic education. State-of-the-art facilities and diverse extracurricular activities.',
    'distance': 2.8,
    'rating': 4.6,
    'reviews': 203,
    'gradeLevel': 'middle',
    'genderType': 'boys_school',
    'schoolType': 'private',
    'city': 'riyadh',
    'institutionType': 'Private',
    'gender_type': 'Boys',
    'curriculum': ['American'],
    'education_levels': ['Primary', 'Intermediate', 'Secondary'],
    'accreditation': ['MOE Saudi', 'NEASC'],
    'fees': {'min': 30000, 'max': 55000, 'currency': 'SAR'},
    'facilities': ['Swimming Pool', 'STEM Labs', 'Auditorium', 'Sports Complex', 'Library'],
    'transportation': true,
    'capacity': 1500,
    'contact': {
      'phone': '+966112345678',
      'email': 'admissions@riyadhschools.edu.sa',
      'website': 'https://riyadhschools.edu.sa'
    },
    'location': {
      'city': 'Riyadh',
      'area': 'Al Wurud',
      'latitude': 24.7500,
      'longitude': 46.6500
    },
    'admission_requirements': ['Birth Certificate', 'Previous School Records', 'Entrance Test', 'Interview'],
    'status': ApplicationStatus.inReview,
    'appliedDate': DateTime.now().subtract(const Duration(days: 3)),
  },
  {
    'name': 'British International School',
    'type': InstitutionType.schools,
    'logo': 'assets/images/British International School.png',
    'description': 'British curriculum school following Cambridge standards. Strong emphasis on academic excellence and character development.',
    'distance': 4.2,
    'rating': 4.4,
    'reviews': 178,
    'gradeLevel': 'high_school',
    'genderType': 'co_education',
    'schoolType': 'international',
    'city': 'riyadh',
    'institutionType': 'International',
    'gender_type': 'Co-Education',
    'curriculum': ['British'],
    'education_levels': ['Kindergarten', 'Primary', 'Secondary'],
    'accreditation': ['MOE Saudi', 'Cambridge'],
    'fees': {'min': 40000, 'max': 65000, 'currency': 'SAR'},
    'facilities': ['Science Labs', 'ICT Suites', 'Art Studios', 'Sports Hall', 'Library'],
    'transportation': true,
    'capacity': 1100,
    'contact': {
      'phone': '+966118765432',
      'email': 'info@britishschool.edu.sa',
      'website': 'https://britishschool.edu.sa'
    },
    'location': {
      'city': 'Riyadh',
      'area': 'Al Mohammadiyah',
      'latitude': 24.7800,
      'longitude': 46.6900
    },
    'admission_requirements': ['Passport Copy', 'Previous Reports', 'Assessment Test', 'Family Interview'],
    'status': ApplicationStatus.accepted,
    'appliedDate': DateTime.now().subtract(const Duration(days: 10)),
  },
  {
    'name': 'Al-Noor Girls School',
    'type': InstitutionType.schools,
    'logo': 'assets/images/Al-Noor Girls School.png',
    'description': 'Exclusive girls school focusing on academic excellence and Islamic values. Modern facilities with dedicated female staff.',
    'distance': 5.1,
    'rating': 4.2,
    'reviews': 145,
    'gradeLevel': 'primary',
    'genderType': 'girls_school',
    'schoolType': 'private',
    'city': 'riyadh',
    'institutionType': 'Private',
    'gender_type': 'Girls',
    'curriculum': ['Saudi National'],
    'education_levels': ['Primary', 'Intermediate'],
    'accreditation': ['MOE Saudi'],
    'fees': {'min': 18000, 'max': 35000, 'currency': 'SAR'},
    'facilities': ['Science Lab', 'Computer Lab', 'Library', 'Prayer Room', 'Playground'],
    'transportation': true,
    'capacity': 800,
    'contact': {
      'phone': '+966115556789',
      'email': 'info@alnoorschool.edu.sa',
      'website': 'https://alnoorschool.edu.sa'
    },
    'location': {
      'city': 'Riyadh',
      'area': 'Al Malaz',
      'latitude': 24.6500,
      'longitude': 46.7200
    },
    'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records'],
    'status': ApplicationStatus.applied,
    'appliedDate': DateTime.now().subtract(const Duration(days: 7)),
  },
  {
    'name': 'Indian International School',
    'type': InstitutionType.schools,
    'logo': 'assets/images/Indian International School.png',
    'description': 'CBSE curriculum school providing quality Indian education with global perspective. Focus on academic rigor and cultural values.',
    'distance': 6.3,
    'rating': 4.1,
    'reviews': 167,
    'gradeLevel': 'kindergarten',
    'genderType': 'co_education',
    'schoolType': 'international',
    'city': 'riyadh',
    'institutionType': 'International',
    'gender_type': 'Co-Education',
    'curriculum': ['Indian'],
    'education_levels': ['Kindergarten', 'Primary', 'Secondary'],
    'accreditation': ['MOE Saudi', 'CBSE'],
    'fees': {'min': 15000, 'max': 30000, 'currency': 'SAR'},
    'facilities': ['Smart Classes', 'Computer Lab', 'Library', 'Sports Ground', 'Activity Room'],
    'transportation': true,
    'capacity': 1200,
    'contact': {
      'phone': '+966114445566',
      'email': 'admin@indianschool.edu.sa',
      'website': 'https://indianschool.edu.sa'
    },
    'location': {
      'city': 'Riyadh',
      'area': 'Al Faisaliyah',
      'latitude': 24.6900,
      'longitude': 46.6800
    },
    'admission_requirements': ['Passport Copy', 'Transfer Certificate', 'Birth Certificate', 'Photos'],
    'status': ApplicationStatus.inReview,
    'appliedDate': DateTime.now().subtract(const Duration(days: 4)),
  },

  // ========== COLLEGES (First 5 from home screen) ==========
  {
    'name': 'King Saud University',
    'type': InstitutionType.colleges,
    'logo': 'assets/images/King Saud University.png',
    'description': 'Premier public research university offering diverse programs in medicine, engineering, sciences, and humanities.',
    'distance': 7.2,
    'rating': 4.7,
    'reviews': 245,
    'institutionType': 'public_university',
    'genderSystem': 'co_ed',
    'gender_type': 'Co-Education',
    'streams': ['Medicine', 'Engineering', 'Science', 'Business', 'Humanities'],
    'courses': [
      {
        'id': 'KSU-MED-BS',
        'name': 'MBBS Medicine',
        'degree': 'Bachelor',
        'duration_years': 6,
        'fees_per_year': 0
      },
      {
        'id': 'KSU-ENG-BS',
        'name': 'BSc Computer Engineering',
        'degree': 'Bachelor',
        'duration_years': 4,
        'fees_per_year': 0
      },
      {
        'id': 'KSU-BUS-MBA',
        'name': 'MBA Business Administration',
        'degree': 'Master',
        'duration_years': 2,
        'fees_per_year': 15000
      }
    ],
    'accreditation': ['MOE Saudi', 'NCAAA'],
    'fees': {'min': 0, 'max': 20000, 'currency': 'SAR'},
    'facilities': ['Research Centers', 'Libraries', 'Hospitals', 'Sports Complex', 'Student Housing'],
    'transportation': true,
    'capacity': 35000,
    'contact': {
      'phone': '+966114680000',
      'email': 'admission@ksu.edu.sa',
      'website': 'https://ksu.edu.sa'
    },
    'location': {
      'city': 'Riyadh',
      'area': 'Al Diriyah',
      'latitude': 24.7225,
      'longitude': 46.6256
    },
    'admission_requirements': ['High School Certificate', 'Qiyas Test', 'Tahsili Test', 'GPA 90%+'],
    'status': ApplicationStatus.accepted,
    'appliedDate': DateTime.now().subtract(const Duration(days: 15)),
  },
  {
    'name': 'King Fahd University of Petroleum & Minerals',
    'type': InstitutionType.colleges,
    'logo': 'assets/images/King Fahd University of Petroleum & Minerals.png',
    'description': 'Leading university specializing in engineering, petroleum, and mineral sciences. Known for strong industry connections.',
    'distance': 8.7,
    'rating': 4.7,
    'reviews': 189,
    'institutionType': 'public_university',
    'genderSystem': 'male_campus',
    'gender_type': 'Male Campus',
    'streams': ['Engineering', 'Computer Science', 'Science', 'Business'],
    'courses': [
      {
        'id': 'KFUPM-CS-BS',
        'name': 'BSc Computer Science',
        'degree': 'Bachelor',
        'duration_years': 4,
        'fees_per_year': 6000
      },
      {
        'id': 'KFUPM-ENG-BE',
        'name': 'BEng Petroleum Engineering',
        'degree': 'Bachelor',
        'duration_years': 5,
        'fees_per_year': 7000
      },
      {
        'id': 'KFUPM-ENG-MS',
        'name': 'MSc Chemical Engineering',
        'degree': 'Master',
        'duration_years': 2,
        'fees_per_year': 12000
      }
    ],
    'accreditation': ['MOE Saudi', 'ABET'],
    'fees': {'min': 0, 'max': 8000, 'currency': 'SAR'},
    'facilities': ['Research Labs', 'Library', 'Sports Complex', 'Student Housing', 'Labs'],
    'transportation': true,
    'capacity': 8000,
    'contact': {
      'phone': '+966138600000',
      'email': 'info@kfupm.edu.sa',
      'website': 'https://kfupm.edu.sa'
    },
    'location': {
      'city': 'Dammam',
      'area': 'Dhahran',
      'latitude': 26.3114,
      'longitude': 50.1472
    },
    'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test', 'Passport/Iqama'],
    'status': ApplicationStatus.inReview,
    'appliedDate': DateTime.now().subtract(const Duration(days: 12)),
  },
  {
    'name': 'Princess Nourah bint Abdulrahman University',
    'type': InstitutionType.colleges,
    'logo': 'assets/images/Princess Nourah bint Abdulrahman University.png',
    'description': 'Largest women university in the world offering comprehensive programs in health sciences, education, and arts.',
    'distance': 6.8,
    'rating': 4.5,
    'reviews': 215,
    'institutionType': 'women_university',
    'genderSystem': 'female_campus',
    'gender_type': 'Female Campus',
    'streams': ['Health Sciences', 'Education', 'Arts', 'Science', 'Business'],
    'courses': [
      {
        'id': 'PNU-MED-BS',
        'name': 'BSc Nursing',
        'degree': 'Bachelor',
        'duration_years': 4,
        'fees_per_year': 0
      },
      {
        'id': 'PNU-EDU-BS',
        'name': 'BEd Early Childhood',
        'degree': 'Bachelor',
        'duration_years': 4,
        'fees_per_year': 0
      },
      {
        'id': 'PNU-ART-BS',
        'name': 'BA Design',
        'degree': 'Bachelor',
        'duration_years': 4,
        'fees_per_year': 5000
      }
    ],
    'accreditation': ['MOE Saudi', 'NCAAA'],
    'fees': {'min': 0, 'max': 10000, 'currency': 'SAR'},
    'facilities': ['Medical Center', 'Library', 'Sports Hall', 'Research Centers', 'Student Housing'],
    'transportation': true,
    'capacity': 60000,
    'contact': {
      'phone': '+966114240000',
      'email': 'admission@pnu.edu.sa',
      'website': 'https://pnu.edu.sa'
    },
    'location': {
      'city': 'Riyadh',
      'area': 'Al Narjis',
      'latitude': 24.8400,
      'longitude': 46.7300
    },
    'admission_requirements': ['High School Certificate', 'Qiyas Test', 'Personal Interview', 'Medical Fitness'],
    'status': ApplicationStatus.applied,
    'appliedDate': DateTime.now().subtract(const Duration(days: 8)),
  },
  {
    'name': 'King Abdulaziz University',
    'type': InstitutionType.colleges,
    'logo': 'assets/images/King Abdulaziz University.png',
    'description': 'Major public university with strong programs in marine sciences, engineering, and medical fields.',
    'distance': 9.3,
    'rating': 4.6,
    'reviews': 198,
    'institutionType': 'public_university',
    'genderSystem': 'co_ed',
    'gender_type': 'Co-Education',
    'streams': ['Marine Science', 'Engineering', 'Medicine', 'Business', 'Arts'],
    'courses': [
      {
        'id': 'KAU-SCI-BS',
        'name': 'BSc Marine Biology',
        'degree': 'Bachelor',
        'duration_years': 4,
        'fees_per_year': 0
      },
      {
        'id': 'KAU-ENG-BS',
        'name': 'BSc Electrical Engineering',
        'degree': 'Bachelor',
        'duration_years': 4,
        'fees_per_year': 0
      },
      {
        'id': 'KAU-MED-MD',
        'name': 'MD Medicine',
        'degree': 'Bachelor',
        'duration_years': 6,
        'fees_per_year': 0
      }
    ],
    'accreditation': ['MOE Saudi', 'ABET'],
    'fees': {'min': 0, 'max': 15000, 'currency': 'SAR'},
    'facilities': ['Marine Station', 'Research Vessels', 'Libraries', 'Hospitals', 'Sports Complex'],
    'transportation': true,
    'capacity': 180000,
    'contact': {
      'phone': '+966126952222',
      'email': 'admission@kau.edu.sa',
      'website': 'https://kau.edu.sa'
    },
    'location': {
      'city': 'Jeddah',
      'area': 'Al Faisaliyah',
      'latitude': 21.4858,
      'longitude': 39.2376
    },
    'admission_requirements': ['High School Certificate', 'Qiyas Test', 'Achievement Test', 'English Proficiency'],
    'status': ApplicationStatus.inReview,
    'appliedDate': DateTime.now().subtract(const Duration(days: 11)),
  },
  {
    'name': 'Hail University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 21.5,
      'rating': 4.0,
      'reviews': 123,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Education', 'Arts', 'Science', 'Business'],
      'courses': [
        {
          'id': 'HU-EDU-BS',
          'name': 'BEd',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'HU-ARTS-BS',
          'name': 'BA Arabic Language',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'HU-SCI-MS',
          'name': 'MSc Mathematics',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 12000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 7000, 'currency': 'SAR'},
      'facilities': ['Library', 'Labs', 'Sports Complex', 'Student Housing'],
      'transportation': true,
      'capacity': 10000,
      'contact': {
        'phone': '+966165300000',
        'email': 'info@uoh.edu.sa',
        'website': 'https://uoh.edu.sa'
      },
      'location': {
        'city': 'Hail',
        'area': 'Al Jamiah',
        'latitude': 27.5114,
        'longitude': 41.7208
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test'],
    'status': ApplicationStatus.inReview,
    'appliedDate': DateTime.now().subtract(const Duration(days: 11)),
  },
];
  */

  // List<Map<String, dynamic>> get _filteredInstitutions {
  //   // Return all institutions without filtering
  //   return _appliedInstitutions;
  // }

  // Helper method to parse date from API format
  DateTime _parseDateTime(String dateString) {
    try {
      // Try parsing with space separator (e.g., "2025-12-04 13:12:15")
      if (dateString.contains(' ')) {
        return DateTime.parse(dateString.replaceAll(' ', 'T'));
      }
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $dateString - $e');
      return DateTime.now();
    }
  }

  // Helper method to format date
String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

  // Helper method to convert status number to string
  String _getStatusString(dynamic status) {
    if (status == null) return 'pending';
    
    // Handle both number and string formats
    if (status is int) {
      switch (status) {
        case 0:
          return 'applied';
        case 1:
          return 'in_review';
        case 2:
          return 'accepted';
        case 3:
          return 'rejected';
        default:
          return 'pending';
      }
    } else if (status is String) {
      return status.toLowerCase();
    }
    
    return 'pending';
  }

  // Helper method to get first character of institution name
  String _getFirstCharacter(String name) {
    if (name.isEmpty) return '?';
    final trimmed = name.trim();
    return trimmed[0].toUpperCase();
  }

  // Build star rating widget for vertical cards
  Widget _buildStarRatingForVertical(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full stars
        ...List.generate(fullStars, (index) => const Icon(
          Icons.star,
          size: 14,
          color: Colors.amber,
        )),
        // Half star
        if (hasHalfStar)
          const Icon(
            Icons.star_half,
            size: 14,
            color: Colors.amber,
          ),
        // Empty stars
        ...List.generate(emptyStars, (index) => const Icon(
          Icons.star_border,
          size: 14,
          color: Colors.grey,
        )),
      ],
    );
  }

  // Helper method to convert institution name to translation key
  String _getNameKey(String name) {
    final nameMap = {
      'Al-Faisal International School': 'al_faisal_international_school',
      'Riyadh Schools': 'riyadh_schools',
      'British International School': 'british_international_school',
      'Al-Noor Girls School': 'al_noor_girls_school',
      'King Fahd School': 'king_fahd_school',
      'King Saud University': 'king_saud_university',
      'King Fahd University of Petroleum & Minerals': 'king_fahd_university_petroleum',
      'Princess Nourah bint Abdulrahman University': 'princess_nourah_university',
      'King Abdulaziz University': 'king_abdulaziz_university',
      'Alfaisal University': 'alfaisal_university',
    };
    return nameMap[name] ?? name.toLowerCase().replaceAll(' ', '_');
  }


  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final localizations = AppLocalizations.of(context);


    return KeyedSubtree(
      key: ValueKey(currentLocale.languageCode),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          
         
          title: Text(
            localizations?.translate('applied_colleges') ?? 'Applied Colleges',
            style: const TextStyle(
              color: AppTheme.primaryIndigo,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            // Search Icon
            IconButton(
              icon: const Icon(
                Icons.search,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(
                      institutions: _appliedInstitutions,
                    ),
                  ),
                );
              },
            ),
            // Notification Icon
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: () {
                // TODO: Navigate to notifications screen
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                              Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadApplications,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _appliedInstitutions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  localizations?.translate('no_applications') ?? 'No applications yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                 children: _appliedInstitutions
                              .map((institution) => _buildVerticalInstitutionCard(
                                    context,
                                    institution,
                                    localizations,
                                  ))
                      .toList(),
                ),
        ),
      ),
    );
  }

  // Vertical card for applied institutions (same format as home screen)
  Widget _buildVerticalInstitutionCard(
    BuildContext context,
    Map<String, dynamic> institution,
    AppLocalizations? localizations,
  ) {
    // Handle API format (name) - the API returns 'name' in the institution object
    final institutionName = institution['name'] as String? ?? 
                           institution['institution_name'] as String? ?? 
                           'Unknown';
    final nameKey = _getNameKey(institutionName);
    final displayName = localizations?.translate(nameKey) ?? institutionName;
    
    // Get rating from API data (avg_rating) or local data (rating)
    final rating = institution['avg_rating'] != null
        ? double.tryParse(institution['avg_rating'].toString()) ?? 0.0
        : (institution['rating'] as num?)?.toDouble() ?? 0.0;
    
    // Get total reviews
    final totalReviews = institution['total_reviews'] as int? ?? 
                        institution['reviews'] as int? ?? 0;
    
    // Get city
    final city = institution['city'] as String? ?? 
                (institution['location'] as Map<String, dynamic>?)?['city'] as String? ?? '';
    
    // Get first character for logo
    final firstChar = _getFirstCharacter(institutionName);
    
    // Get applied date
    final appliedDate = institution['appliedDate'] is DateTime
        ? institution['appliedDate'] as DateTime
        : (institution['created_at'] != null
            ? _parseDateTime(institution['created_at'] as String)
            : DateTime.now());
    
    return InkWell(
      onTap: () {
        final applicationId = institution['application_id'] as int?;
        if (applicationId != null) {
          // Navigate to ApplicationFormScreen with application ID for editing
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApplicationFormScreen(
                institution: institution,
                isSchool: (institution['institution_type'] as String? ?? '').toLowerCase() == 'school',
                applicationId: applicationId,
              ),
            ),
          );
        } else {
          // Fallback to institution details if no application ID
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstitutionDetailsScreen(
                institution: institution,
                hideApplyButton: true,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
              blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
            child: Row(
              children: [
            // Logo with first character
                Container(
              width: 60,
              height: 60,
                  decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryIndigo.withOpacity(0.1),
                    border: Border.all(
                  color: AppTheme.primaryIndigo.withOpacity(0.3),
                  width: 2,
                    ),
                  ),
              child: Center(
                child: Text(
                  firstChar,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryIndigo,
                  ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
            // Institution details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    displayName,
                              style: const TextStyle(
                      fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                          Icons.location_on,
                            size: 14,
                          color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                          city,
                            style: TextStyle(
                            fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                  // Always show rating if avg_rating or rating field exists (even if 0)
                  if (institution.containsKey('avg_rating') || institution.containsKey('rating')) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStarRatingForVertical(rating),
                        const SizedBox(width: 8),
                        Text(
                          '($totalReviews ${localizations?.translate('reviews') ?? 'reviews'})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Applied Date
                  const SizedBox(height: 6),
                  Text(
                    '${localizations?.translate('applied_on') ?? 'Applied on'}: ${_formatDate(appliedDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
