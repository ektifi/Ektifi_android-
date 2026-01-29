import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../api/api_service.dart';
import '../../services/auth_service.dart';
import '../institution_details_screen.dart';
import '../search_screen.dart';

enum InstitutionType {
  schools,
  colleges,
}

class HomeScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  
  const HomeScreen({super.key, this.onLocaleChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Method to reload data when tab becomes visible
  void reloadData() {
    // Reload colleges/schools data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInstitutions();
      _fetchTopColleges();
    });
  }

  String? _selectedLocation = 'Riyadh'; // Default location
  String? _selectedEducationLevel; // For filter chips (nursery, kindergarten, etc.)
  PageController? _bannerPageController;
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // API data
  List<Map<String, dynamic>> _apiColleges = [];
  bool _isLoadingColleges = false;
  String? _collegesError;
  
  // Top colleges data (for above banner)
  List<Map<String, dynamic>> _topColleges = [];
  bool _isLoadingTopColleges = false;
  String? _topCollegesError;

  // Auth service to check education type
  final AuthService _authService = AuthService();

  // School Filters
  String? _selectedCurriculum;
  String? _selectedGradeLevel;
  String? _selectedGenderType;
  String? _selectedSchoolType;
  String? _selectedCity;

  // College Filters
  String? _selectedInstitutionType;
  String? _selectedFieldOfStudy;
  String? _selectedDegreeType;
  String? _selectedGenderSystem;
  String? _selectedCollegeCity;

  // Filter option keys (using translation keys)
  final List<String> _curriculumOptions = [
    'saudi_national',
    'british',
    'american',
    'indian',
    'ib',
    'philippine',
    'pakistani',
    'french',
    'canadian',
  ];

  final List<String> _gradeLevelOptions = [
    'kindergarten',
    'primary',
    'middle',
    'high_school',
  ];

  final List<String> _genderTypeOptions = [
    'boys_school',
    'girls_school',
    'co_education',
  ];

  final List<String> _schoolTypeOptions = [
    'public',
    'private',
    'international',
    'charter',
  ];

  final List<String> _cityOptions = [
    'riyadh',
    'jeddah',
    'dammam',
    'khobar',
    'medina',
    'mecca',
    'abha',
    'tabuk',
    'jubail',
    'yanbu',
  ];

  final List<String> _institutionTypeOptions = [
    'public_university',
    'private_university',
    'community_college',
    'technical_vocational',
    'medical_college',
    'women_university',
  ];

  final List<String> _fieldOfStudyOptions = [
    'engineering_technology',
    'medicine_health',
    'business_management',
    'computer_science_it',
    'science_research',
    'law_islamic_studies',
    'arts_humanities',
    'education',
    'design_architecture',
  ];

  final List<String> _degreeTypeOptions = [
    'diploma',
    'bachelors',
    'masters',
    'phd',
    'vocational_certificates',
  ];

  final List<String> _genderSystemOptions = [
    'male_campus',
    'female_campus',
    'co_ed',
  ];

  final List<String> _collegeCityOptions = [
    'riyadh',
    'jeddah',
    'dammam',
    'khobar',
    'medina',
    'mecca',
    'abha',
    'tabuk',
    'qassim',
    'hail',
  ];

  // Sample institutions data - 20 Schools and 20 Colleges
  final List<Map<String, dynamic>> _institutions = [
    // ========== SCHOOLS (20) ==========
    {
      'name': 'Al-Faisal International School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/Al-Faisal International School.avif',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 3.1,
      'rating': 4.3,
      'reviews': 156,
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
    },
    {
      'name': 'Riyadh Schools',
      'type': InstitutionType.schools,
      'logo': 'assets/images/Riyadh Schools.png',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 6.5,
      'rating': 4.6,
      'reviews': 278,
      'institutionType': 'Private',
      'gender_type': 'Boys',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 15000, 'max': 28000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Sports Field', 'Prayer Room'],
      'transportation': true,
      'capacity': 1500,
      'contact': {
        'phone': '+966114567891',
        'email': 'info@riyadhschools.edu.sa'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'Al Malaz',
        'latitude': 24.6500,
        'longitude': 46.7200
      },
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records'],
    },
    {
      'name': 'British International School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/British International School.png',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 4.2,
      'rating': 4.5,
      'reviews': 189,
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['British', 'IB elective'],
      'education_levels': ['Kindergarten', 'Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['Cambridge', 'IB Candidate'],
      'fees': {'min': 30000, 'max': 55000, 'currency': 'SAR'},
      'facilities': ['Music Room', 'STEM Lab', 'Library', 'Sports Complex', 'Swimming Pool', 'Theater'],
      'transportation': true,
      'capacity': 800,
      'contact': {
        'phone': '+966126789012',
        'email': 'info@britishschool.edu.sa',
        'website': 'https://britishschool.edu.sa'
      },
      'location': {
        'city': 'Jeddah',
        'area': 'Al Hamra',
        'latitude': 21.5433,
        'longitude': 39.1728
      },
      'admission_requirements': ['Placement Test', 'Parent ID', 'Previous School Records', 'English Proficiency Test'],
    },
    {
      'name': 'Al-Noor Girls School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/Al-Noor Girls School.png',
      'distance': 5.8,
      'rating': 4.4,
      'reviews': 203,
      'gradeLevel': 'primary',
      'genderType': 'girls_school',
      'schoolType': 'public',
      'city': 'riyadh',
      'institutionType': 'Public',
      'gender_type': 'Girls',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 0, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab'],
      'transportation': false,
      'capacity': 900,
      'contact': {'phone': '+966114567892'},
      'location': {'city': 'Riyadh', 'area': 'Al Naseem', 'latitude': 24.6800, 'longitude': 46.7300},
      'admission_requirements': ['National ID', 'Birth Certificate'],
    },
    {
      'name': 'Indian International School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/Indian International School.png',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 7.3,
      'rating': 4.2,
      'reviews': 145,
      'gradeLevel': 'middle',
      'genderType': 'co_education',
      'schoolType': 'international',
      'city': 'dammam',
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['Indian'],
      'education_levels': ['Kindergarten', 'Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['CBSE', 'MOE Saudi'],
      'fees': {'min': 18000, 'max': 32000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Sports Field', 'Cafeteria'],
      'transportation': true,
      'capacity': 1100,
      'contact': {'phone': '+966133456789', 'email': 'info@indianschool.edu.sa'},
      'location': {'city': 'Dammam', 'area': 'Al Faisaliyah', 'latitude': 26.4207, 'longitude': 50.0888},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records'],
    },
    {
      'name': 'King Fahd School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/King Fahd School.png',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 8.1,
      'rating': 4.7,
      'reviews': 312,
      'gradeLevel': 'high_school',
      'genderType': 'boys_school',
      'schoolType': 'private',
      'city': 'jeddah',
      'institutionType': 'Private',
      'gender_type': 'Boys',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 20000, 'max': 35000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Sports Complex', 'Auditorium'],
      'transportation': true,
      'capacity': 1800,
      'contact': {'phone': '+966126789013', 'email': 'info@kingfahdschool.edu.sa'},
      'location': {'city': 'Jeddah', 'area': 'Al Rawdah', 'latitude': 21.4858, 'longitude': 39.1925},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records', 'Entrance Exam'],
    },
    {
      'name': 'IB World School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 5.5,
      'rating': 4.6,
      'reviews': 167,
      'gradeLevel': 'primary',
      'genderType': 'co_education',
      'schoolType': 'international',
      'city': 'riyadh',
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['IB'],
      'education_levels': ['Kindergarten', 'Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['IBO', 'CIS'],
      'fees': {'min': 35000, 'max': 60000, 'currency': 'SAR'},
      'facilities': ['STEM Lab', 'Library', 'Arts Center', 'Sports Complex', 'Swimming Pool', 'Theater'],
      'transportation': true,
      'capacity': 750,
      'contact': {'phone': '+966114567893', 'email': 'info@ibworld.edu.sa', 'website': 'https://ibworld.edu.sa'},
      'location': {'city': 'Riyadh', 'area': 'Al Wurud', 'latitude': 24.6900, 'longitude': 46.6800},
      'admission_requirements': ['Placement Test', 'Parent ID', 'Previous School Records', 'English Proficiency'],
    },
    {
      'name': 'Al-Ahsa Girls Academy',
      'type': InstitutionType.schools,
      'logo': 'assets/images/Al-Ahsa Girls Academy.webp',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 9.2,
      'rating': 4.3,
      'reviews': 198,
      'gradeLevel': 'middle',
      'genderType': 'girls_school',
      'schoolType': 'private',
      'city': 'khobar',
      'institutionType': 'Private',
      'gender_type': 'Girls',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 12000, 'max': 25000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Arts Room', 'Prayer Room'],
      'transportation': true,
      'capacity': 650,
      'contact': {'phone': '+966133456790'},
      'location': {'city': 'Khobar', 'area': 'Al Aziziyah', 'latitude': 26.2794, 'longitude': 50.2080},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records'],
    },
    {
      'name': 'Philippine School of Riyadh',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 6.7,
      'rating': 4.1,
      'reviews': 134,
      'gradeLevel': 'primary',
      'genderType': 'co_education',
      'schoolType': 'international',
      'city': 'riyadh',
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['Philippine'],
      'education_levels': ['Kindergarten', 'Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['DepEd Philippines', 'MOE Saudi'],
      'fees': {'min': 15000, 'max': 28000, 'currency': 'SAR'},
      'facilities': ['Library', 'Computer Lab', 'Sports Field', 'Cafeteria', 'Music Room'],
      'transportation': true,
      'capacity': 850,
      'contact': {'phone': '+966114567894', 'email': 'info@psr.edu.sa'},
      'location': {'city': 'Riyadh', 'area': 'Al Olaya', 'latitude': 24.7000, 'longitude': 46.6900},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records'],
    },
    {
      'name': 'Pakistani International School',
      'type': InstitutionType.schools,
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 7.9,
      'rating': 4.0,
      'reviews': 112,
      'gradeLevel': 'middle',
      'genderType': 'co_education',
      'schoolType': 'international',
      'city': 'jeddah',
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['Pakistani'],
      'education_levels': ['Kindergarten', 'Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['FBISE', 'MOE Saudi'],
      'fees': {'min': 14000, 'max': 26000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Sports Field'],
      'transportation': true,
      'capacity': 720,
      'contact': {'phone': '+966126789014', 'email': 'info@pakistanischool.edu.sa'},
      'location': {'city': 'Jeddah', 'area': 'Al Hamra', 'latitude': 21.5433, 'longitude': 39.1728},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records'],
    },
    {
      'name': 'French International School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'description': 'Leading private school following Saudi National Curriculum with strong focus on academic achievement and Islamic values. Modern facilities and comprehensive student support services.',
      'distance': 4.8,
      'rating': 4.4,
      'reviews': 156,
      'gradeLevel': 'high_school',
      'genderType': 'co_education',
      'schoolType': 'international',
      'city': 'riyadh',
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['French'],
      'education_levels': ['Kindergarten', 'Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['AEFE', 'MOE Saudi'],
      'fees': {'min': 28000, 'max': 48000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Language Lab', 'Sports Complex', 'Arts Center'],
      'transportation': true,
      'capacity': 680,
      'contact': {'phone': '+966114567895', 'email': 'info@frenchschool.edu.sa', 'website': 'https://frenchschool.edu.sa'},
      'location': {'city': 'Riyadh', 'area': 'Al Olaya', 'latitude': 24.7100, 'longitude': 46.6700},
      'admission_requirements': ['Placement Test', 'Parent ID', 'Previous School Records', 'French Proficiency'],
    },
    {
      'name': 'Canadian International School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 5.3,
      'rating': 4.5,
      'reviews': 178,
      'gradeLevel': 'primary',
      'genderType': 'co_education',
      'schoolType': 'international',
      'city': 'dammam',
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['Canadian'],
      'education_levels': ['Kindergarten', 'Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['Alberta Education', 'MOE Saudi'],
      'fees': {'min': 32000, 'max': 52000, 'currency': 'SAR'},
      'facilities': ['Library', 'STEM Lab', 'Sports Complex', 'Swimming Pool', 'Arts Room', 'Music Room'],
      'transportation': true,
      'capacity': 600,
      'contact': {'phone': '+966133456791', 'email': 'info@canadianschool.edu.sa', 'website': 'https://canadianschool.edu.sa'},
      'location': {'city': 'Dammam', 'area': 'Al Faisaliyah', 'latitude': 26.4207, 'longitude': 50.0888},
      'admission_requirements': ['Placement Test', 'Parent ID', 'Previous School Records', 'English Proficiency'],
    },
    {
      'name': 'Al-Madinah Boys School',
      'type': InstitutionType.schools,
      'distance': 10.5,
      'rating': 4.2,
      'reviews': 223,
      'gradeLevel': 'high_school',
      'genderType': 'boys_school',
      'schoolType': 'public',
      'city': 'medina',
      'institutionType': 'Public',
      'gender_type': 'Boys',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 0, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Sports Field', 'Prayer Room'],
      'transportation': false,
      'capacity': 1100,
      'contact': {'phone': '+966144567896'},
      'location': {'city': 'Medina', 'area': 'Al Qiblatain', 'latitude': 24.4681, 'longitude': 39.6142},
      'admission_requirements': ['National ID', 'Birth Certificate'],
    },
    {
      'name': 'Mecca Girls School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 11.2,
      'rating': 4.3,
      'reviews': 189,
      'gradeLevel': 'primary',
      'genderType': 'girls_school',
      'schoolType': 'public',
      'city': 'mecca',
      'institutionType': 'Public',
      'gender_type': 'Girls',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 0, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Arts Room'],
      'transportation': false,
      'capacity': 950,
      'contact': {'phone': '+966125678901'},
      'location': {'city': 'Mecca', 'area': 'Al Aziziyah', 'latitude': 21.3891, 'longitude': 39.8579},
      'admission_requirements': ['National ID', 'Birth Certificate'],
    },
    {
      'name': 'Charter School of Excellence',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 6.2,
      'rating': 4.6,
      'reviews': 245,
      'gradeLevel': 'middle',
      'genderType': 'co_education',
      'schoolType': 'charter',
      'city': 'riyadh',
      'institutionType': 'Charter',
      'gender_type': 'Co-Education',
      'curriculum': ['American'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['AdvancED', 'MOE Saudi'],
      'fees': {'min': 22000, 'max': 40000, 'currency': 'SAR'},
      'facilities': ['Library', 'STEM Lab', 'Sports Complex', 'Arts Center', 'Computer Lab'],
      'transportation': true,
      'capacity': 1000,
      'contact': {'phone': '+966114567897', 'email': 'info@charterschool.edu.sa'},
      'location': {'city': 'Riyadh', 'area': 'Al Malaz', 'latitude': 24.6500, 'longitude': 46.7200},
      'admission_requirements': ['Placement Test', 'Parent ID', 'Previous School Records'],
    },
    {
      'name': 'Al-Abha International School',
      'type': InstitutionType.schools,
      'distance': 15.8,
      'rating': 4.1,
      'reviews': 98,
      'gradeLevel': 'high_school',
      'genderType': 'co_education',
      'schoolType': 'international',
      'city': 'abha',
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['British'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['Cambridge', 'MOE Saudi'],
      'fees': {'min': 26000, 'max': 45000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Sports Field', 'Arts Room'],
      'transportation': true,
      'capacity': 580,
      'contact': {'phone': '+966172345678', 'email': 'info@abhaschool.edu.sa'},
      'location': {'city': 'Abha', 'area': 'Al Sahab', 'latitude': 18.2164, 'longitude': 42.5042},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records', 'English Test'],
    },
    {
      'name': 'Tabuk Boys Academy',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 18.3,
      'rating': 4.0,
      'reviews': 167,
      'gradeLevel': 'middle',
      'genderType': 'boys_school',
      'schoolType': 'private',
      'city': 'tabuk',
      'institutionType': 'Private',
      'gender_type': 'Boys',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 16000, 'max': 30000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Sports Field', 'Prayer Room'],
      'transportation': true,
      'capacity': 800,
      'contact': {'phone': '+966144567898'},
      'location': {'city': 'Tabuk', 'area': 'Al Faisaliyah', 'latitude': 28.3998, 'longitude': 36.5700},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records'],
    },
    {
      'name': 'Jubail Girls School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 12.7,
      'rating': 4.2,
      'reviews': 134,
      'gradeLevel': 'primary',
      'genderType': 'girls_school',
      'schoolType': 'private',
      'city': 'jubail',
      'institutionType': 'Private',
      'gender_type': 'Girls',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 13000, 'max': 26000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Arts Room', 'Prayer Room'],
      'transportation': true,
      'capacity': 700,
      'contact': {'phone': '+966133456792'},
      'location': {'city': 'Jubail', 'area': 'Al Fanateer', 'latitude': 27.0174, 'longitude': 49.6225},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records'],
    },
    {
      'name': 'Yanbu International Academy',
      'type': InstitutionType.schools,
      'distance': 14.5,
      'rating': 4.4,
      'reviews': 156,
      'gradeLevel': 'high_school',
      'genderType': 'co_education',
      'schoolType': 'international',
      'city': 'yanbu',
      'institutionType': 'Private',
      'gender_type': 'Co-Education',
      'curriculum': ['IB'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['IBO', 'MOE Saudi'],
      'fees': {'min': 30000, 'max': 55000, 'currency': 'SAR'},
      'facilities': ['STEM Lab', 'Library', 'Sports Complex', 'Arts Center', 'Swimming Pool'],
      'transportation': true,
      'capacity': 650,
      'contact': {'phone': '+966144567899', 'email': 'info@yanbuacademy.edu.sa'},
      'location': {'city': 'Yanbu', 'area': 'Al Sinaiyah', 'latitude': 24.0892, 'longitude': 38.0618},
      'admission_requirements': ['Placement Test', 'Parent ID', 'Previous School Records', 'English Proficiency'],
    },
    {
      'name': 'Al-Khobar Private School',
      'type': InstitutionType.schools,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 8.9,
      'rating': 4.5,
      'reviews': 201,
      'gradeLevel': 'primary',
      'genderType': 'boys_school',
      'schoolType': 'private',
      'city': 'khobar',
      'institutionType': 'Private',
      'gender_type': 'Boys',
      'curriculum': ['Saudi National'],
      'education_levels': ['Primary', 'Intermediate', 'Secondary'],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 17000, 'max': 32000, 'currency': 'SAR'},
      'facilities': ['Library', 'Science Labs', 'Computer Lab', 'Sports Field', 'Prayer Room', 'Auditorium'],
      'transportation': true,
      'capacity': 1300,
      'contact': {'phone': '+966133456793', 'email': 'info@khobarschool.edu.sa'},
      'location': {'city': 'Khobar', 'area': 'Al Aziziyah', 'latitude': 26.2794, 'longitude': 50.2080},
      'admission_requirements': ['National ID', 'Birth Certificate', 'Previous School Records', 'Entrance Exam'],
    },
    
    // ========== COLLEGES/UNIVERSITIES (20) ==========
    {
      'name': 'King Saud University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/King Saud University.jpeg',
      'distance': 5.2,
      'rating': 4.5,
      'reviews': 234,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Engineering', 'Medicine', 'Business', 'Computer Science', 'Science'],
      'courses': [
        {
          'id': 'KSU-CS-BS',
          'name': 'BSc Computer Science',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'KSU-ENG-BE',
          'name': 'BEng Mechanical Engineering',
          'degree': 'Bachelor',
          'duration_years': 5,
          'fees_per_year': 6000
        },
        {
          'id': 'KSU-MBA',
          'name': 'MBA',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 15000
        }
      ],
      'accreditation': ['Ministry of Education (Saudi)', 'National Qualifications Authority'],
      'fees': {'min': 0, 'max': 8000, 'currency': 'SAR'},
      'facilities': ['Research Centers', 'Medical Center', 'Hostels', 'Library', 'Sports Complex', 'Labs'],
      'transportation': true,
      'capacity': 52000,
      'contact': {
        'phone': '+966114670000',
        'email': 'info@ksu.edu.sa',
        'website': 'https://ksu.edu.sa'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'King Saud University Campus',
        'latitude': 24.7236,
        'longitude': 46.6200
      },
      'city': 'riyadh',
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test (when required)', 'Passport/Iqama'],
    },
    {
      'name': 'King Fahd University of Petroleum & Minerals',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/King Fahd University of Petroleum & Minerals.png',
      'distance': 8.7,
      'rating': 4.7,
      'reviews': 189,
      'institutionType': 'Public University',
      'gender_type': 'Male Campus',
      'streams': ['Engineering', 'Computer Science', 'Science'],
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
    },
    {
      'name': 'Princess Nourah bint Abdulrahman University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/Princess Nourah bint Abdulrahman University.png',
      'distance': 12.3,
      'rating': 4.4,
      'reviews': 312,
      'institutionType': 'Women University',
      'gender_type': 'Female Campus',
      'streams': ['Education', 'Medicine', 'Science', 'Arts'],
      'courses': [
        {
          'id': 'PNU-EDU-BS',
          'name': 'BEd Elementary Education',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'PNU-MED-BS',
          'name': 'BSc Nursing',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 6000
        },
        {
          'id': 'PNU-EDU-MS',
          'name': 'MEd Educational Leadership',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 12000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 7000, 'currency': 'SAR'},
      'facilities': ['Library', 'Medical Center', 'Student Housing', 'Sports Complex', 'Labs', 'Research Centers'],
      'transportation': true,
      'capacity': 60000,
      'contact': {
        'phone': '+966114000000',
        'email': 'info@pnu.edu.sa',
        'website': 'https://pnu.edu.sa'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'Al Narjis',
        'latitude': 24.7236,
        'longitude': 46.6200
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test (when required)', 'Passport/Iqama'],
    },
    {
      'name': 'King Abdulaziz University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/King Abdulaziz University.jpeg',
      'distance': 9.5,
      'rating': 4.6,
      'reviews': 267,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Engineering', 'Medicine', 'Business', 'Law', 'IT & Computer Science'],
      'courses': [
        {
          'id': 'KAU-MBA',
          'name': 'MBA',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 15000
        },
        {
          'id': 'KAU-MED-BS',
          'name': 'MBBS',
          'degree': 'Bachelor',
          'duration_years': 6,
          'fees_per_year': 7000
        },
        {
          'id': 'KAU-ENG-BE',
          'name': 'BEng Civil Engineering',
          'degree': 'Bachelor',
          'duration_years': 5,
          'fees_per_year': 6000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 9000, 'currency': 'SAR'},
      'facilities': ['Research Labs', 'Auditoriums', 'Student Housing', 'Library', 'Medical Center'],
      'transportation': true,
      'capacity': 40000,
      'contact': {
        'phone': '+966126400000',
        'website': 'https://kau.edu.sa'
      },
      'location': {
        'city': 'Jeddah',
        'area': 'Sari Street',
        'latitude': 21.543333,
        'longitude': 39.172778
      },
      'admission_requirements': ['Secondary Certificate', 'Transcripts', 'Standardized Test Scores'],
    },
    {
      'name': 'Imam Muhammad ibn Saud Islamic University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/Imam Muhammad ibn Saud Islamic University.png',
      'distance': 6.8,
      'rating': 4.3,
      'reviews': 198,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Islamic Law', 'Education', 'Arabic Language', 'Sharia'],
      'courses': [
        {
          'id': 'IMSIU-LAW-BS',
          'name': 'LLB Islamic Law',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'IMSIU-EDU-BS',
          'name': 'BEd Islamic Education',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'IMSIU-LAW-PHD',
          'name': 'PhD Islamic Jurisprudence',
          'degree': 'PhD',
          'duration_years': 4,
          'fees_per_year': 10000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 8000, 'currency': 'SAR'},
      'facilities': ['Library', 'Research Centers', 'Auditoriums', 'Student Housing', 'Prayer Rooms'],
      'transportation': true,
      'capacity': 25000,
      'contact': {
        'phone': '+966114588888',
        'email': 'info@imamu.edu.sa',
        'website': 'https://imamu.edu.sa'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'Al Malaz',
        'latitude': 24.6500,
        'longitude': 46.7200
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test', 'Passport/Iqama'],
    },
    {
      'name': 'King Faisal University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/King Faisal University.jpeg',
      'distance': 7.4,
      'rating': 4.5,
      'reviews': 223,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Medicine', 'Engineering', 'Business', 'Agriculture'],
      'courses': [
        {
          'id': 'KFU-MED-BS',
          'name': 'MBBS',
          'degree': 'Bachelor',
          'duration_years': 6,
          'fees_per_year': 7000
        },
        {
          'id': 'KFU-ENG-BE',
          'name': 'BEng Electrical Engineering',
          'degree': 'Bachelor',
          'duration_years': 5,
          'fees_per_year': 6000
        },
        {
          'id': 'KFU-BUS-MBA',
          'name': 'MBA',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 15000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 8000, 'currency': 'SAR'},
      'facilities': ['Medical Center', 'Research Labs', 'Library', 'Sports Complex', 'Student Housing'],
      'transportation': true,
      'capacity': 18000,
      'contact': {
        'phone': '+966133588888',
        'email': 'info@kfu.edu.sa',
        'website': 'https://kfu.edu.sa'
      },
      'location': {
        'city': 'Dammam',
        'area': 'Al Hofuf',
        'latitude': 25.4200,
        'longitude': 49.6222
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test', 'Passport/Iqama'],
    },
    {
      'name': 'Umm Al-Qura University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/Umm Al-Qura University.png',
      'distance': 11.8,
      'rating': 4.2,
      'reviews': 189,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Islamic Law', 'Medicine', 'Education', 'Engineering'],
      'courses': [
        {
          'id': 'UQU-LAW-BS',
          'name': 'LLB Sharia Law',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'UQU-MED-BS',
          'name': 'MBBS',
          'degree': 'Bachelor',
          'duration_years': 6,
          'fees_per_year': 7000
        },
        {
          'id': 'UQU-EDU-MS',
          'name': 'MEd',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 12000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 8000, 'currency': 'SAR'},
      'facilities': ['Library', 'Medical Center', 'Research Centers', 'Student Housing', 'Sports Complex'],
      'transportation': true,
      'capacity': 15000,
      'contact': {
        'phone': '+966125570000',
        'email': 'info@uqu.edu.sa',
        'website': 'https://uqu.edu.sa'
      },
      'location': {
        'city': 'Mecca',
        'area': 'Al Aziziyah',
        'latitude': 21.3891,
        'longitude': 39.8579
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test', 'Passport/Iqama'],
    },
    {
      'name': 'Taif University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/Taif University.png',
      'distance': 13.2,
      'rating': 4.1,
      'reviews': 145,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Education', 'Arts', 'Science', 'Business'],
      'courses': [
        {
          'id': 'TU-EDU-BS',
          'name': 'BEd',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'TU-ARTS-BS',
          'name': 'BA Arabic Literature',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'TU-SCI-MS',
          'name': 'MSc Chemistry',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 12000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 7000, 'currency': 'SAR'},
      'facilities': ['Library', 'Labs', 'Sports Complex', 'Student Housing'],
      'transportation': true,
      'capacity': 12000,
      'contact': {
        'phone': '+966127320000',
        'email': 'info@tu.edu.sa'
      },
      'location': {
        'city': 'Mecca',
        'area': 'Taif',
        'latitude': 21.2703,
        'longitude': 40.4158
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test'],
    },
    {
      'name': 'King Khalid University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/King Khalid University.png',
      'distance': 16.5,
      'rating': 4.3,
      'reviews': 167,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Medicine', 'Engineering', 'Education', 'Science'],
      'courses': [
        {
          'id': 'KKU-MED-BS',
          'name': 'MBBS',
          'degree': 'Bachelor',
          'duration_years': 6,
          'fees_per_year': 7000
        },
        {
          'id': 'KKU-ENG-BE',
          'name': 'BEng Civil Engineering',
          'degree': 'Bachelor',
          'duration_years': 5,
          'fees_per_year': 6000
        },
        {
          'id': 'KKU-EDU-MS',
          'name': 'MEd',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 12000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 8000, 'currency': 'SAR'},
      'facilities': ['Medical Center', 'Research Labs', 'Library', 'Sports Complex', 'Student Housing'],
      'transportation': true,
      'capacity': 14000,
      'contact': {
        'phone': '+966172241111',
        'email': 'info@kku.edu.sa',
        'website': 'https://kku.edu.sa'
      },
      'location': {
        'city': 'Abha',
        'area': 'Al Sahab',
        'latitude': 18.2164,
        'longitude': 42.5042
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test', 'Passport/Iqama'],
    },
    {
      'name': 'Alfaisal University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/Alfaisal University.jpeg',
      'distance': 4.9,
      'rating': 4.7,
      'reviews': 178,
      'institutionType': 'Private University',
      'gender_type': 'Co-Education',
      'streams': ['Business', 'Engineering', 'Medicine', 'Science'],
      'courses': [
        {
          'id': 'AU-BUS-BS',
          'name': 'BBA',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 80000
        },
        {
          'id': 'AU-ENG-BE',
          'name': 'BEng Mechanical Engineering',
          'degree': 'Bachelor',
          'duration_years': 5,
          'fees_per_year': 90000
        },
        {
          'id': 'AU-MED-BS',
          'name': 'MBBS',
          'degree': 'Bachelor',
          'duration_years': 6,
          'fees_per_year': 120000
        },
        {
          'id': 'AU-BUS-MBA',
          'name': 'MBA',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 150000
        }
      ],
      'accreditation': ['MOE Saudi', 'AACSB'],
      'fees': {'min': 80000, 'max': 150000, 'currency': 'SAR'},
      'facilities': ['Research Centers', 'Medical Center', 'Library', 'Sports Complex', 'Student Housing', 'Labs'],
      'transportation': true,
      'capacity': 3000,
      'contact': {
        'phone': '+966114151111',
        'email': 'info@alfaisal.edu',
        'website': 'https://alfaisal.edu'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'Al Olaya',
        'latitude': 24.7136,
        'longitude': 46.6753
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'SAT/ACT Scores', 'English Proficiency', 'Interview'],
    },
    {
      'name': 'Prince Sultan University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/Prince Sultan University.png',
      'distance': 5.6,
      'rating': 4.4,
      'reviews': 156,
      'institutionType': 'Private University',
      'gender_type': 'Co-Education',
      'streams': ['Computer Science', 'Business', 'Engineering', 'Architecture'],
      'courses': [
        {
          'id': 'PSU-CS-BS',
          'name': 'BSc Computer Science',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 70000
        },
        {
          'id': 'PSU-BUS-BS',
          'name': 'BBA',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 65000
        },
        {
          'id': 'PSU-CS-MS',
          'name': 'MSc Computer Science',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 80000
        }
      ],
      'accreditation': ['MOE Saudi', 'ABET'],
      'fees': {'min': 65000, 'max': 100000, 'currency': 'SAR'},
      'facilities': ['Library', 'Computer Labs', 'Sports Complex', 'Student Housing', 'Research Labs'],
      'transportation': true,
      'capacity': 2500,
      'contact': {
        'phone': '+966114540000',
        'email': 'info@psu.edu.sa',
        'website': 'https://psu.edu.sa'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'Al Wurud',
        'latitude': 24.6900,
        'longitude': 46.6800
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'SAT/ACT Scores', 'English Proficiency'],
    },
    {
      'name': 'Effat University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/Effat University.jpeg',
      'distance': 8.3,
      'rating': 4.5,
      'reviews': 201,
      'institutionType': 'Women University',
      'gender_type': 'Female Campus',
      'streams': ['Design', 'Business', 'Engineering', 'Architecture'],
      'courses': [
        {
          'id': 'EFFAT-DES-BS',
          'name': 'BFA Graphic Design',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 75000
        },
        {
          'id': 'EFFAT-BUS-BS',
          'name': 'BBA',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 70000
        },
        {
          'id': 'EFFAT-ENG-BE',
          'name': 'BEng Electrical Engineering',
          'degree': 'Bachelor',
          'duration_years': 5,
          'fees_per_year': 85000
        }
      ],
      'accreditation': ['MOE Saudi', 'ABET'],
      'fees': {'min': 70000, 'max': 100000, 'currency': 'SAR'},
      'facilities': ['Library', 'Design Studios', 'Labs', 'Sports Complex', 'Student Housing', 'Arts Center'],
      'transportation': true,
      'capacity': 2000,
      'contact': {
        'phone': '+966126360000',
        'email': 'info@effat.edu.sa',
        'website': 'https://effat.edu.sa'
      },
      'location': {
        'city': 'Jeddah',
        'area': 'Al Hamra',
        'latitude': 21.5433,
        'longitude': 39.1728
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'SAT/ACT Scores', 'English Proficiency', 'Portfolio (for Design)'],
    },
    {
      'name': 'Dar Al-Hekma University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 7.8,
      'rating': 4.6,
      'reviews': 189,
      'institutionType': 'Women University',
      'gender_type': 'Female Campus',
      'streams': ['Design', 'Business', 'Arts', 'Architecture'],
      'courses': [
        {
          'id': 'DAH-DES-BS',
          'name': 'BFA Interior Design',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 80000
        },
        {
          'id': 'DAH-BUS-BS',
          'name': 'BBA',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 75000
        },
        {
          'id': 'DAH-ARTS-BS',
          'name': 'BA English Literature',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 70000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 70000, 'max': 100000, 'currency': 'SAR'},
      'facilities': ['Library', 'Design Studios', 'Arts Center', 'Sports Complex', 'Student Housing'],
      'transportation': true,
      'capacity': 1800,
      'contact': {
        'phone': '+966126300000',
        'email': 'info@dahedu.sa',
        'website': 'https://dahedu.sa'
      },
      'location': {
        'city': 'Jeddah',
        'area': 'Al Hamra',
        'latitude': 21.5433,
        'longitude': 39.1728
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'SAT/ACT Scores', 'English Proficiency', 'Portfolio'],
    },
    {
      'name': 'King Saud bin Abdulaziz University for Health Sciences',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 6.1,
      'rating': 4.8,
      'reviews': 245,
      'institutionType': 'Medical College',
      'gender_type': 'Co-Education',
      'streams': ['Medicine', 'Nursing', 'Pharmacy', 'Dentistry'],
      'courses': [
        {
          'id': 'KSAUHS-MED-BS',
          'name': 'MBBS',
          'degree': 'Bachelor',
          'duration_years': 6,
          'fees_per_year': 8000
        },
        {
          'id': 'KSAUHS-NUR-BS',
          'name': 'BSc Nursing',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 6000
        },
        {
          'id': 'KSAUHS-MED-MS',
          'name': 'MSc Public Health',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 15000
        },
        {
          'id': 'KSAUHS-MED-PHD',
          'name': 'PhD Medicine',
          'degree': 'PhD',
          'duration_years': 4,
          'fees_per_year': 20000
        }
      ],
      'accreditation': ['MOE Saudi', 'WHO'],
      'fees': {'min': 0, 'max': 10000, 'currency': 'SAR'},
      'facilities': ['Medical Center', 'Research Labs', 'Hospital', 'Library', 'Student Housing'],
      'transportation': true,
      'capacity': 5000,
      'contact': {
        'phone': '+966114290000',
        'email': 'info@ksau-hs.edu.sa',
        'website': 'https://ksau-hs.edu.sa'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'Al Malaz',
        'latitude': 24.6500,
        'longitude': 46.7200
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test', 'Medical Exam', 'Passport/Iqama'],
    },
    {
      'name': 'King Saud Medical City College',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 5.4,
      'rating': 4.5,
      'reviews': 198,
      'institutionType': 'Medical College',
      'gender_type': 'Co-Education',
      'streams': ['Medicine', 'Nursing', 'Allied Health'],
      'courses': [
        {
          'id': 'KSMCC-MED-BS',
          'name': 'MBBS',
          'degree': 'Bachelor',
          'duration_years': 6,
          'fees_per_year': 7500
        },
        {
          'id': 'KSMCC-NUR-BS',
          'name': 'BSc Nursing',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5500
        },
        {
          'id': 'KSMCC-MED-MS',
          'name': 'MSc Clinical Medicine',
          'degree': 'Master',
          'duration_years': 2,
          'fees_per_year': 14000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 9000, 'currency': 'SAR'},
      'facilities': ['Medical Center', 'Hospital', 'Labs', 'Library', 'Student Housing'],
      'transportation': true,
      'capacity': 3000,
      'contact': {
        'phone': '+966114011111',
        'email': 'info@ksmcc.edu.sa'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'Al Malaz',
        'latitude': 24.6500,
        'longitude': 46.7200
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test', 'Medical Exam'],
    },
    {
      'name': 'Riyadh Community College',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 4.7,
      'rating': 4.2,
      'reviews': 134,
      'institutionType': 'Community College',
      'gender_type': 'Co-Education',
      'streams': ['Business', 'Computer Science', 'Engineering Technology'],
      'courses': [
        {
          'id': 'RCC-BUS-DIP',
          'name': 'Diploma in Business Administration',
          'degree': 'Diploma',
          'duration_years': 2,
          'fees_per_year': 15000
        },
        {
          'id': 'RCC-CS-BS',
          'name': 'BSc Computer Science',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 25000
        },
        {
          'id': 'RCC-ENG-DIP',
          'name': 'Diploma in Engineering Technology',
          'degree': 'Diploma',
          'duration_years': 2,
          'fees_per_year': 18000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 15000, 'max': 30000, 'currency': 'SAR'},
      'facilities': ['Library', 'Computer Labs', 'Workshops', 'Sports Complex'],
      'transportation': true,
      'capacity': 5000,
      'contact': {
        'phone': '+966114567777',
        'email': 'info@rcc.edu.sa'
      },
      'location': {
        'city': 'Riyadh',
        'area': 'Al Malaz',
        'latitude': 24.6500,
        'longitude': 46.7200
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts'],
    },
    {
      'name': 'Jeddah Technical College',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 9.1,
      'rating': 4.3,
      'reviews': 167,
      'institutionType': 'Technical Vocational',
      'gender_type': 'Male Campus',
      'streams': ['Engineering Technology', 'Computer Science', 'Automotive', 'Electrical'],
      'courses': [
        {
          'id': 'JTC-ENG-DIP',
          'name': 'Diploma in Mechanical Engineering',
          'degree': 'Diploma',
          'duration_years': 2,
          'fees_per_year': 20000
        },
        {
          'id': 'JTC-CS-CERT',
          'name': 'Certificate in Network Administration',
          'degree': 'Vocational Certificate',
          'duration_years': 1,
          'fees_per_year': 15000
        },
        {
          'id': 'JTC-AUTO-CERT',
          'name': 'Certificate in Automotive Technology',
          'degree': 'Vocational Certificate',
          'duration_years': 1,
          'fees_per_year': 18000
        }
      ],
      'accreditation': ['MOE Saudi', 'TVTC'],
      'fees': {'min': 15000, 'max': 25000, 'currency': 'SAR'},
      'facilities': ['Workshops', 'Labs', 'Library', 'Training Centers'],
      'transportation': true,
      'capacity': 4000,
      'contact': {
        'phone': '+966126789999',
        'email': 'info@jeddahtech.edu.sa'
      },
      'location': {
        'city': 'Jeddah',
        'area': 'Al Hamra',
        'latitude': 21.5433,
        'longitude': 39.1728
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Technical Aptitude Test'],
    },
    {
      'name': 'Dammam Technical College',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 8.5,
      'rating': 4.1,
      'reviews': 145,
      'institutionType': 'Technical Vocational',
      'gender_type': 'Co-Education',
      'streams': ['Engineering Technology', 'Business', 'IT', 'Hospitality'],
      'courses': [
        {
          'id': 'DTC-ENG-DIP',
          'name': 'Diploma in Civil Engineering Technology',
          'degree': 'Diploma',
          'duration_years': 2,
          'fees_per_year': 19000
        },
        {
          'id': 'DTC-BUS-DIP',
          'name': 'Diploma in Business Management',
          'degree': 'Diploma',
          'duration_years': 2,
          'fees_per_year': 16000
        },
        {
          'id': 'DTC-IT-CERT',
          'name': 'Certificate in Web Development',
          'degree': 'Vocational Certificate',
          'duration_years': 1,
          'fees_per_year': 14000
        }
      ],
      'accreditation': ['MOE Saudi', 'TVTC'],
      'fees': {'min': 14000, 'max': 22000, 'currency': 'SAR'},
      'facilities': ['Workshops', 'Labs', 'Library', 'Training Centers', 'Computer Labs'],
      'transportation': true,
      'capacity': 3500,
      'contact': {
        'phone': '+966133456666',
        'email': 'info@dammamtech.edu.sa'
      },
      'location': {
        'city': 'Dammam',
        'area': 'Al Faisaliyah',
        'latitude': 26.4207,
        'longitude': 50.0888
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts'],
    },
    {
      'name': 'Qassim University',
      'type': InstitutionType.colleges,
      'logo': 'assets/images/ektifi-logo copy.png',
      'distance': 19.2,
      'rating': 4.2,
      'reviews': 178,
      'institutionType': 'Public University',
      'gender_type': 'Co-Education',
      'streams': ['Education', 'Engineering', 'Medicine', 'Agriculture'],
      'courses': [
        {
          'id': 'QU-EDU-BS',
          'name': 'BEd',
          'degree': 'Bachelor',
          'duration_years': 4,
          'fees_per_year': 5000
        },
        {
          'id': 'QU-ENG-BE',
          'name': 'BEng Agricultural Engineering',
          'degree': 'Bachelor',
          'duration_years': 5,
          'fees_per_year': 6000
        },
        {
          'id': 'QU-MED-BS',
          'name': 'MBBS',
          'degree': 'Bachelor',
          'duration_years': 6,
          'fees_per_year': 7000
        }
      ],
      'accreditation': ['MOE Saudi'],
      'fees': {'min': 0, 'max': 8000, 'currency': 'SAR'},
      'facilities': ['Library', 'Research Labs', 'Medical Center', 'Sports Complex', 'Student Housing'],
      'transportation': true,
      'capacity': 16000,
      'contact': {
        'phone': '+966163800000',
        'email': 'info@qu.edu.sa',
        'website': 'https://qu.edu.sa'
      },
      'location': {
        'city': 'Qassim',
        'area': 'Buraydah',
        'latitude': 26.3260,
        'longitude': 43.9750
      },
      'admission_requirements': ['High School Certificate', 'GPA Transcripts', 'Qiyas Test', 'Passport/Iqama'],
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
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
    _startBannerTimer();
    _fetchInstitutions();
    _fetchTopColleges();
  }
  
  Future<void> _fetchInstitutions() async {
    setState(() {
      _isLoadingColleges = true;
      _collegesError = null;
    });
    
    try {
      // Check user's education type
      final educationType = await _authService.getEducationType();
      
      if (educationType == 'school') {
        // Fetch schools if user education type is school
        print('User education type is school, fetching schools...');
        final schools = await ApiService.fetchSchools();
        setState(() {
          _apiColleges = schools;
          _isLoadingColleges = false;
        });
      } else {
        // Fetch colleges if user education type is college or null (default)
        print('User education type is college or null, fetching colleges...');
      final colleges = await ApiService.fetchColleges();
      setState(() {
        _apiColleges = colleges;
        _isLoadingColleges = false;
      });
      }
    } catch (e) {
      setState(() {
        _collegesError = e.toString();
        _isLoadingColleges = false;
      });
      print('Error loading institutions: $e');
    }
  }
  
  // Keep old method name for backward compatibility (used in refresh)
  Future<void> _fetchColleges() async {
    await _fetchInstitutions();
  }
  
  Future<void> _fetchTopColleges() async {
    setState(() {
      _isLoadingTopColleges = true;
      _topCollegesError = null;
    });
    
    try {
      print('Fetching top colleges...');
      final topColleges = await ApiService.fetchTopColleges();
      print('Received ${topColleges.length} top colleges');
      setState(() {
        _topColleges = topColleges;
        _isLoadingTopColleges = false;
      });
      print('Top colleges state updated: ${_topColleges.length} items');
    } catch (e) {
      print('Error loading top colleges: $e');
      setState(() {
        _topCollegesError = e.toString();
        _isLoadingTopColleges = false;
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerPageController != null && _bannerPageController!.hasClients) {
        final nextIndex = (_currentBannerIndex + 1) % 4; // 4 banners total
        _bannerPageController!.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Get popular institutions - use API colleges
  List<Map<String, dynamic>> get _popularInstitutions {
    // Use API colleges if available, otherwise fallback to local data
    List<Map<String, dynamic>> allColleges = [];
    if (_apiColleges.isNotEmpty) {
      allColleges = _apiColleges;
    } else {
      // Fallback to local data
    final schools = _institutions
        .where((inst) => inst['type'] == InstitutionType.schools)
        .take(5)
        .toList();
    final colleges = _institutions
        .where((inst) => inst['type'] == InstitutionType.colleges)
        .take(5)
        .toList();
      allColleges = [...schools, ...colleges];
    }
    
    // Apply search filter if query exists
    if (_searchQuery.isNotEmpty) {
      return allColleges.where((institution) {
        final name = institution['institution_name'] as String? ?? 
                    institution['name'] as String? ?? 
                    '';
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return allColleges.take(10).toList();
  }
  
  // Get filtered top colleges based on search
  List<Map<String, dynamic>> get _filteredTopColleges {
    if (_searchQuery.isEmpty) {
      return _topColleges;
    }
    
    return _topColleges.where((institution) {
      final name = institution['institution_name'] as String? ?? 
                  institution['name'] as String? ?? 
                  '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Get all institutions for search screen (combines API colleges with local data)
  List<Map<String, dynamic>> get _allInstitutions {
    List<Map<String, dynamic>> allInstitutions = List.from(_institutions);
    
    // Add API colleges, mapping them to have the expected structure
    for (var college in _apiColleges) {
      final mappedCollege = Map<String, dynamic>.from(college);
      // Ensure it has 'type' field for SearchScreen filtering
      if (!mappedCollege.containsKey('type')) {
        mappedCollege['type'] = InstitutionType.colleges;
      }
      // Map 'institution_name' to 'name' if needed
      if (mappedCollege.containsKey('institution_name') && !mappedCollege.containsKey('name')) {
        mappedCollege['name'] = mappedCollege['institution_name'];
      }
      allInstitutions.add(mappedCollege);
    }
    
    return allInstitutions;
  }
  
  // Get first character of institution name
  String _getFirstCharacter(String name) {
    if (name.isEmpty) return '?';
    // Remove common prefixes like "The", "A", etc. and get first letter
    final trimmed = name.trim();
    return trimmed[0].toUpperCase();
  }
  
  // Build star rating widget (small for horizontal cards)
  Widget _buildStarRating(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Full stars
        ...List.generate(fullStars, (index) => const Icon(
          Icons.star,
          size: 10,
          color: Colors.amber,
        )),
        // Half star
        if (hasHalfStar)
          const Icon(
            Icons.star_half,
            size: 10,
            color: Colors.amber,
          ),
        // Empty stars
        ...List.generate(emptyStars, (index) => const Icon(
          Icons.star_border,
          size: 10,
          color: Colors.amber,
        )),
      ],
    );
  }
  
  // Build star rating widget (larger for vertical cards)
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
          color: Colors.amber,
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
      'Indian International School': 'indian_international_school',
      'King Fahd School': 'king_fahd_school',
      'IB World School': 'ib_world_school',
      'Al-Ahsa Girls Academy': 'al_ahsa_girls_academy',
      'Philippine School of Riyadh': 'philippine_school_riyadh',
      'Pakistani International School': 'pakistani_international_school',
      'French International School': 'french_international_school',
      'Canadian International School': 'canadian_international_school',
      'Al-Madinah Boys School': 'al_madinah_boys_school',
      'Mecca Girls School': 'mecca_girls_school',
      'Charter School of Excellence': 'charter_school_excellence',
      'Al-Abha International School': 'al_abha_international_school',
      'Tabuk Boys Academy': 'tabuk_boys_academy',
      'Jubail Girls School': 'jubail_girls_school',
      'Yanbu International Academy': 'yanbu_international_academy',
      'Al-Khobar Private School': 'al_khobar_private_school',
      'King Saud University': 'king_saud_university',
      'King Fahd University of Petroleum & Minerals': 'king_fahd_university_petroleum',
      'Princess Nourah bint Abdulrahman University': 'princess_nourah_university',
      'King Abdulaziz University': 'king_abdulaziz_university',
      'Imam Muhammad ibn Saud Islamic University': 'imam_muhammad_university',
      'King Faisal University': 'king_faisal_university',
      'Umm Al-Qura University': 'umm_al_qura_university',
      'Taif University': 'taif_university',
      'King Khalid University': 'king_khalid_university',
      'Alfaisal University': 'alfaisal_university',
      'Prince Sultan University': 'prince_sultan_university',
      'Effat University': 'effat_university',
      'Dar Al-Hekma University': 'dar_al_hekma_university',
      'King Saud bin Abdulaziz University for Health Sciences': 'king_saud_health_sciences',
      'King Saud Medical City College': 'king_saud_medical_city',
      'Riyadh Community College': 'riyadh_community_college',
      'Jeddah Technical College': 'jeddah_technical_college',
      'Dammam Technical College': 'dammam_technical_college',
      'Qassim University': 'qassim_university',
      'Hail University': 'hail_university',
    };
    return nameMap[name] ?? name.toLowerCase().replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final localizations = AppLocalizations.of(context);
    
    // This ensures the widget rebuilds when locale changes
    // The currentLocale is used to trigger rebuilds

    return KeyedSubtree(
      key: ValueKey(currentLocale.languageCode),
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Container(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          height: 40,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: localizations?.translate('search_colleges_schools') ?? 'Search colleges or schools',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
            onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            enableInteractiveSelection: true,
            readOnly: false,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onSubmitted: (value) {
              // Handle search submission if needed
              FocusScope.of(context).unfocus();
            },
          ),
        ),
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
                    institutions: _allInstitutions,
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
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Education Level Filters
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              child: SizedBox(
                height: 85,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildEducationLevelChip(
                      'assets/images/nursery.png',
                      localizations?.translate('nursery') ?? 'Nursery',
                      'nursery',
                      localizations,
                    ),
                    const SizedBox(width: 12),
                    _buildEducationLevelChip(
                      'assets/images/kindergarden.png',
                      localizations?.translate('kindergarten') ?? 'Kindergarten',
                      'kindergarten',
                      localizations,
                    ),
                    const SizedBox(width: 12),
                    _buildEducationLevelChip(
                      'assets/images/primary_school.png',
                      localizations?.translate('primary') ?? 'Primary',
                      'primary_school',
                      localizations,
                    ),
                    const SizedBox(width: 12),
                    _buildEducationLevelChip(
                      'assets/images/middle_school.png',
                      localizations?.translate('middle') ?? 'Middle',
                      'middle_school',
                      localizations,
                    ),
                    const SizedBox(width: 12),
                    _buildEducationLevelChip(
                      'assets/images/high_school.png',
                      localizations?.translate('high_school') ?? 'High School',
                      'high_school',
                      localizations,
                    ),
                    const SizedBox(width: 12),
                    _buildEducationLevelChip(
                      'assets/images/college.png',
                      localizations?.translate('colleges') ?? 'Colleges',
                      'colleges',
                      localizations,
                    ),
                    const SizedBox(width: 12),
                    _buildEducationLevelChip(
                      'assets/images/university.png',
                      localizations?.translate('university') ?? 'University',
                      'university',
                      localizations,
                    ),
                  ],
                ),
              ),
            ),
            // Top Colleges Section (Above Banner)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.translate('popular_schools_and_colleges') ?? 'Popular Schools and Colleges',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 130,
                    child: _isLoadingTopColleges
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : _topCollegesError != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red[300],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error loading top colleges',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _topCollegesError!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: _fetchTopColleges,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryIndigo,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _filteredTopColleges.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.school_outlined,
                                            color: Colors.grey[400],
                                            size: 32,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            localizations?.translate('no_results') ?? 'No results found',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView(
                      scrollDirection: Axis.horizontal,
                                    children: _filteredTopColleges.map((institution) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildPopularInstitutionCard(context, institution, localizations),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Promotional Banners Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //   child: Text(
                  //     localizations?.translate('featured_institutions') ?? 'Featured Institutions',
                  //     style: const TextStyle(
                  //       fontSize: 18,
                  //       fontWeight: FontWeight.bold,
                  //       color: Colors.black87,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: PageView.builder(
                      controller: _bannerPageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                        // Reset timer when user manually swipes
                        _startBannerTimer();
                      },
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final banners = [
                          {
                            'name': 'King Saud University',
                            'tag': localizations?.translate('admission_open') ?? 'Admission Open',
                            'logo': 'assets/images/King Saud University.jpeg',
                            'color': AppTheme.primaryIndigo,
                          },
                          {
                            'name': 'Al-Faisal International School',
                            'tag': localizations?.translate('special_offers') ?? 'Special Offers',
                            'logo': 'assets/images/Al-Faisal International School.avif',
                            'color': AppTheme.accentCyan,
                          },
                          {
                            'name': 'Princess Nourah bint Abdulrahman University',
                            'tag': localizations?.translate('admission_open') ?? 'Admission Open',
                            'logo': 'assets/images/Princess Nourah bint Abdulrahman University.png',
                            'color': Colors.purple,
                          },
                          {
                            'name': 'British International School',
                            'tag': localizations?.translate('special_offers') ?? 'Special Offers',
                            'logo': 'assets/images/British International School.png',
                            'color': Colors.blue,
                          },
                        ];
                        
                        final banner = banners[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildPromotionalBanner(
                            context,
                            banner['name'] as String,
                            banner['tag'] as String,
                            banner['logo'] as String,
                            banner['color'] as Color,
                            localizations,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Colleges List Section (Vertical Scrolling)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: _isLoadingColleges
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _collegesError != null
                          ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                      'Error loading colleges',
                              style: TextStyle(
                                color: Colors.grey[600],
                                        fontSize: 14,
                              ),
                            ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _fetchColleges,
                                      child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                          : _popularInstitutions.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      localizations?.translate('no_results') ?? 'No results found',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _popularInstitutions.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: _buildVerticalInstitutionCard(
                                        context,
                                        _popularInstitutions[index],
                                        localizations,
                                      ),
                                    );
                                  },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPopularInstitutionCard(
    BuildContext context,
    Map<String, dynamic> institution,
    AppLocalizations? localizations,
  ) {
    // Handle both API format (institution_name) and local format (name)
    final institutionName = institution['institution_name'] as String? ?? 
                           institution['name'] as String? ?? 
                           'Unknown';
    final nameKey = _getNameKey(institutionName);
    final displayName = localizations?.translate(nameKey) ?? institutionName;
    
    // Get rating from API data (avg_rating) or local data (rating)
    final rating = institution['avg_rating'] != null
        ? double.tryParse(institution['avg_rating'].toString()) ?? 0.0
        : (institution['rating'] as num?)?.toDouble() ?? 0.0;
    
    // Get first character for logo
    final firstChar = _getFirstCharacter(institutionName);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstitutionDetailsScreen(
              institution: institution,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryIndigo,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (rating > 0) ...[
              const SizedBox(height: 4),
              _buildStarRating(rating),
            ],
          ],
        ),
      ),
    );
  }

  // Vertical card for vertical scrolling list
  Widget _buildVerticalInstitutionCard(
    BuildContext context,
    Map<String, dynamic> institution,
    AppLocalizations? localizations,
  ) {
    // Handle both API format (institution_name) and local format (name)
    final institutionName = institution['institution_name'] as String? ?? 
                           institution['name'] as String? ?? 
                           'Unknown';
    final nameKey = _getNameKey(institutionName);
    final displayName = localizations?.translate(nameKey) ?? institutionName;
    
    // Get rating from API data (avg_rating) or local data (rating)
    final rating = institution['avg_rating'] != null
        ? (institution['avg_rating'] is num 
            ? (institution['avg_rating'] as num).toDouble()
            : double.tryParse(institution['avg_rating'].toString()) ?? 0.0)
        : (institution['rating'] as num?)?.toDouble() ?? 0.0;
    
    // Get total reviews
    final totalReviews = institution['total_reviews'] != null
        ? (institution['total_reviews'] is int
            ? institution['total_reviews'] as int
            : int.tryParse(institution['total_reviews'].toString()) ?? 0)
        : (institution['reviews'] as int?) ?? 0;
    
    // Get city
    final city = institution['city'] as String? ?? '';
    
    // Get first character for logo
    final firstChar = _getFirstCharacter(institutionName);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstitutionDetailsScreen(
              institution: institution,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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

  Widget _buildPromotionalBanner(
    BuildContext context,
    String institutionName,
    String tag,
    String logoPath,
    Color backgroundColor,
    AppLocalizations? localizations,
  ) {
    final nameKey = _getNameKey(institutionName);
    final displayName = localizations?.translate(nameKey) ?? institutionName;
    
    return InkWell(
      onTap: () {
        // Find the institution and navigate to details
        final institution = _institutions.firstWhere(
          (inst) => inst['name'] == institutionName,
          orElse: () => _institutions.first,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstitutionDetailsScreen(
              institution: institution,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
        child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Logo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/ektifi-logo copy.png',
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationLevelChip(
    String imagePath,
    String label,
    String value,
    AppLocalizations? localizations,
  ) {
    final isSelected = _selectedEducationLevel == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedEducationLevel = isSelected ? null : value;
        });
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color.fromARGB(255, 137, 132, 244) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color.fromARGB(255, 137, 132, 244) : Colors.white,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryIndigo : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


}
