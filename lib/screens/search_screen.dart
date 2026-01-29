import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../api/api_service.dart';
import 'filters_screen.dart';
import 'institution_details_screen.dart';
import 'home/home_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Map<String, dynamic>> institutions;

  const SearchScreen({
    super.key,
    required this.institutions,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  InstitutionType _selectedType = InstitutionType.schools;

  // Filter states
  String? _selectedCurriculum;
  String? _selectedGradeLevel;
  String? _selectedGenderType;
  String? _selectedSchoolType;
  String? _selectedCity;
  String? _selectedInstitutionType;
  String? _selectedFieldOfStudy;
  String? _selectedDegreeType;
  String? _selectedGenderSystem;
  String? _selectedCollegeCity;

  // Filter option keys
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

  List<Map<String, dynamic>> get _institutions => widget.institutions;

  // API filtered results for schools
  List<Map<String, dynamic>> _apiFilteredSchools = [];
  bool _isLoadingFilteredSchools = false;
  String? _filteredSchoolsError;
  bool _hasActiveSchoolFilters = false;

  // API filtered results for colleges
  List<Map<String, dynamic>> _apiFilteredColleges = [];
  bool _isLoadingFilteredColleges = false;
  String? _filteredCollegesError;
  bool _hasActiveCollegeFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to map UI filter values to API format
  String? _mapGenderTypeToApi(String? genderType) {
    if (genderType == null) return null;
    // Map: boys_school -> "boys school", girls_school -> "girls school", co_education -> "co-education"
    return genderType.replaceAll('_', ' ');
  }

  String? _mapGradeLevelToProgramLevel(String? gradeLevel) {
    if (gradeLevel == null) return null;
    // Map grade levels to program levels
    switch (gradeLevel) {
      case 'kindergarten':
        return '1-6';
      case 'primary':
        return '1-6';
      case 'middle':
        return '7-9';
      case 'high_school':
        return '10-12';
      default:
        return gradeLevel;
    }
  }

  String? _mapCityToApi(String? city) {
    if (city == null) return null;
    // Capitalize first letter for API (e.g., "riyadh" -> "Riyadh")
    if (city.isEmpty) return null;
    return city.substring(0, 1).toUpperCase() + city.substring(1);
  }

  String? _mapCurriculumToApi(String? curriculum) {
    if (curriculum == null) return null;
    // Return curriculum as is (lowercase)
    return curriculum.toLowerCase();
  }

  // Helper methods for college filters
  String? _mapInstitutionTypeToCollegeType(String? institutionType) {
    if (institutionType == null) return null;
    // Map UI values to API format
    // public_university -> "Public University", private_university -> "Private University", etc.
    switch (institutionType) {
      case 'public_university':
        return 'Public University';
      case 'private_university':
        return 'Private University';
      case 'community_college':
        return 'Community College';
      case 'technical_vocational':
        return 'Technical Vocational';
      case 'medical_college':
        return 'Medical College';
      case 'women_university':
        return 'Women University';
      default:
        // Try to format: "public_university" -> "Public University"
        return institutionType
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  String? _mapFieldOfStudyToProgramLevel(String? fieldOfStudy) {
    if (fieldOfStudy == null) return null;
    // Map field of study to program level format
    // engineering_technology -> "engineering & technology"
    return fieldOfStudy.replaceAll('_', ' & ');
  }

  String? _mapDegreeTypeToApi(String? degreeType) {
    if (degreeType == null) return null;
    // Return degree type as is (might need formatting)
    return degreeType.toLowerCase();
  }

  String? _mapGenderSystemToApi(String? genderSystem) {
    if (genderSystem == null) return null;
    // Map college gender system to API format
    // male_campus -> "boys school", female_campus -> "girls school", co_ed -> "co-education"
    switch (genderSystem) {
      case 'male_campus':
        return 'male campus';
      case 'female_campus':
        return 'female campus';
      case 'co_ed':
        return 'co-education';
      default:
        return genderSystem.replaceAll('_', ' ');
    }
  }

  // Fetch filtered schools from API
  Future<void> _fetchFilteredSchools() async {
    // Check if we have any school filters applied
    final hasFilters = _selectedType == InstitutionType.schools &&
        (_selectedCurriculum != null ||
            _selectedGradeLevel != null ||
            _selectedGenderType != null ||
            _selectedSchoolType != null ||
            _selectedCity != null);

    if (!hasFilters) {
      setState(() {
        _hasActiveSchoolFilters = false;
        _apiFilteredSchools = [];
      });
      return;
    }

    setState(() {
      _isLoadingFilteredSchools = true;
      _filteredSchoolsError = null;
      _hasActiveSchoolFilters = true;
    });

    try {
      final result = await ApiService.filterInstitutions(
        institutionType: 'school',
        schoolType: _selectedSchoolType,
        genderType: _mapGenderTypeToApi(_selectedGenderType),
        programLevel: _mapGradeLevelToProgramLevel(_selectedGradeLevel),
        curriculum: _mapCurriculumToApi(_selectedCurriculum),
        city: _mapCityToApi(_selectedCity),
      );

      setState(() {
        _apiFilteredSchools = result['institutions'] as List<Map<String, dynamic>>;
        _isLoadingFilteredSchools = false;
      });
    } catch (e) {
      print('Error fetching filtered schools: $e');
      setState(() {
        _filteredSchoolsError = e.toString();
        _isLoadingFilteredSchools = false;
        _apiFilteredSchools = [];
      });
    }
  }

  // Fetch filtered colleges from API
  Future<void> _fetchFilteredColleges() async {
    // Check if we have any college filters applied
    final hasFilters = _selectedType == InstitutionType.colleges &&
        (_selectedInstitutionType != null ||
            _selectedFieldOfStudy != null ||
            _selectedDegreeType != null ||
            _selectedGenderSystem != null ||
            _selectedCollegeCity != null);

    if (!hasFilters) {
      setState(() {
        _hasActiveCollegeFilters = false;
        _apiFilteredColleges = [];
      });
      return;
    }

    setState(() {
      _isLoadingFilteredColleges = true;
      _filteredCollegesError = null;
      _hasActiveCollegeFilters = true;
    });

    try {
      final result = await ApiService.filterInstitutions(
        institutionType: 'college',
        collegeType: _mapInstitutionTypeToCollegeType(_selectedInstitutionType),
        genderType: _mapGenderSystemToApi(_selectedGenderSystem),
        programLevel: _mapFieldOfStudyToProgramLevel(_selectedFieldOfStudy),
        city: _mapCityToApi(_selectedCollegeCity),
        degreeType: _mapDegreeTypeToApi(_selectedDegreeType),
        // governing_authority can be added if needed
      );

      setState(() {
        _apiFilteredColleges = result['institutions'] as List<Map<String, dynamic>>;
        _isLoadingFilteredColleges = false;
      });
    } catch (e) {
      print('Error fetching filtered colleges: $e');
      setState(() {
        _filteredCollegesError = e.toString();
        _isLoadingFilteredColleges = false;
        _apiFilteredColleges = [];
      });
    }
  }

List<Map<String, dynamic>> get _filteredInstitutions {
  // If we have API filtered schools, use them instead of local filtering
  if (_selectedType == InstitutionType.schools && _hasActiveSchoolFilters) {
    List<Map<String, dynamic>> filtered = _apiFilteredSchools;
    
    // Apply search query filter on API results
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((institution) {
        final name = institution['institution_name'] as String? ?? 
                    institution['name'] as String? ?? 
                    '';
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  // If we have API filtered colleges, use them instead of local filtering
  if (_selectedType == InstitutionType.colleges && _hasActiveCollegeFilters) {
    List<Map<String, dynamic>> filtered = _apiFilteredColleges;
    
    // Apply search query filter on API results
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((institution) {
        final name = institution['institution_name'] as String? ?? 
                    institution['name'] as String? ?? 
                    '';
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  // Otherwise, use local filtering logic
  return _institutions.where((institution) {
    // Filter by type
    if (institution['type'] != _selectedType) return false;

    // Filter by search query
    if (_searchQuery.isNotEmpty &&
        !institution['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase())) {
      return false;
    }

    if (_selectedType == InstitutionType.schools) {
      // School filters
      if (_selectedCurriculum != null) {
        final curriculum = institution['curriculum'];
        bool matches = false;
        if (curriculum is List) {
          matches = curriculum.any((c) => 
            c.toString().toLowerCase().replaceAll(' ', '_') == _selectedCurriculum);
        } else if (curriculum is String) {
          matches = curriculum.toLowerCase().replaceAll(' ', '_') == _selectedCurriculum;
        }
        if (!matches) return false;
      }
      
      if (_selectedGradeLevel != null) {
        final gradeLevel = institution['gradeLevel'];
        if (gradeLevel == null || gradeLevel.toString().toLowerCase().replaceAll(' ', '_') != _selectedGradeLevel) {
          return false;
        }
      }
      
      if (_selectedGenderType != null) {
        final genderType = institution['genderType'];
        if (genderType == null || genderType.toString().toLowerCase().replaceAll(' ', '_') != _selectedGenderType) {
          return false;
        }
      }
      
      if (_selectedSchoolType != null) {
        final schoolType = institution['schoolType'];
        if (schoolType == null || schoolType.toString().toLowerCase().replaceAll(' ', '_') != _selectedSchoolType) {
          return false;
        }
      }
      
      if (_selectedCity != null) {
        final city = institution['city'];
        if (city == null || city.toString().toLowerCase().replaceAll(' ', '_') != _selectedCity) {
          return false;
        }
      }
    } else {
      // College filters
      if (_selectedInstitutionType != null) {
        final institutionType = institution['institutionType'];
        if (institutionType == null || institutionType.toString().toLowerCase().replaceAll(' ', '_') != _selectedInstitutionType) {
          return false;
        }
      }
      
      if (_selectedFieldOfStudy != null) {
        final fields = institution['fieldOfStudy'];
        bool matches = false;
        if (fields is List) {
          matches = fields.any((field) => 
            field.toString().toLowerCase().replaceAll(' ', '_') == _selectedFieldOfStudy);
        } else if (fields is String) {
          matches = fields.toLowerCase().replaceAll(' ', '_') == _selectedFieldOfStudy;
        }
        if (!matches) return false;
      }
      
      if (_selectedDegreeType != null) {
        final degrees = institution['degreeType'];
        bool matches = false;
        if (degrees is List) {
          matches = degrees.any((degree) => 
            degree.toString().toLowerCase().replaceAll(' ', '_') == _selectedDegreeType);
        } else if (degrees is String) {
          matches = degrees.toLowerCase().replaceAll(' ', '_') == _selectedDegreeType;
        }
        if (!matches) return false;
      }
      
      if (_selectedGenderSystem != null) {
        final genderSystem = institution['genderSystem'];
        if (genderSystem == null || genderSystem.toString().toLowerCase().replaceAll(' ', '_') != _selectedGenderSystem) {
          return false;
        }
      }
      
      if (_selectedCollegeCity != null) {
        // FIX: College city is in location object, not at root level
        final location = institution['location'] as Map<String, dynamic>?;
        final city = location?['city'] as String?;
        if (city == null || city.toString().toLowerCase().replaceAll(' ', '_') != _selectedCollegeCity) {
          return false;
        }
      }
    }

    return true;
  }).toList();
}

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FiltersScreen(
          selectedType: _selectedType,
          // School filters
          selectedCurriculum: _selectedCurriculum,
          selectedGradeLevel: _selectedGradeLevel,
          selectedGenderType: _selectedGenderType,
          selectedSchoolType: _selectedSchoolType,
          selectedCity: _selectedCity,
          // College filters
          selectedInstitutionType: _selectedInstitutionType,
          selectedFieldOfStudy: _selectedFieldOfStudy,
          selectedDegreeType: _selectedDegreeType,
          selectedGenderSystem: _selectedGenderSystem,
          selectedCollegeCity: _selectedCollegeCity,
          // Options
          curriculumOptions: _curriculumOptions,
          gradeLevelOptions: _gradeLevelOptions,
          genderTypeOptions: _genderTypeOptions,
          schoolTypeOptions: _schoolTypeOptions,
          cityOptions: _cityOptions,
          institutionTypeOptions: _institutionTypeOptions,
          fieldOfStudyOptions: _fieldOfStudyOptions,
          degreeTypeOptions: _degreeTypeOptions,
          genderSystemOptions: _genderSystemOptions,
          collegeCityOptions: _collegeCityOptions,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedType = result['selectedType'] as InstitutionType? ?? _selectedType;
        _selectedCurriculum = result['selectedCurriculum'] as String?;
        _selectedGradeLevel = result['selectedGradeLevel'] as String?;
        _selectedGenderType = result['selectedGenderType'] as String?;
        _selectedSchoolType = result['selectedSchoolType'] as String?;
        _selectedCity = result['selectedCity'] as String?;
        _selectedInstitutionType = result['selectedInstitutionType'] as String?;
        _selectedFieldOfStudy = result['selectedFieldOfStudy'] as String?;
        _selectedDegreeType = result['selectedDegreeType'] as String?;
        _selectedGenderSystem = result['selectedGenderSystem'] as String?;
        _selectedCollegeCity = result['selectedCollegeCity'] as String?;
      });

      // If category is school and filters are applied, fetch from API
      if (_selectedType == InstitutionType.schools) {
        _fetchFilteredSchools();
        // Clear college filters
        setState(() {
          _hasActiveCollegeFilters = false;
          _apiFilteredColleges = [];
        });
      } else if (_selectedType == InstitutionType.colleges) {
        _fetchFilteredColleges();
        // Clear school filters
        setState(() {
          _hasActiveSchoolFilters = false;
          _apiFilteredSchools = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRTL ? Icons.arrow_forward : Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: localizations?.translate('search_colleges_schools') ?? 'Search colleges or schools',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune, color: Colors.black87, size: 20),
                onPressed: _openFilters,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ),
      body: Column(
        children: [
          _buildAppliedFiltersChips(localizations),
          Expanded(
            child: (_isLoadingFilteredSchools || _isLoadingFilteredColleges)
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : (_filteredSchoolsError != null || _filteredCollegesError != null)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.errorRed,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedType == InstitutionType.schools
                                    ? 'Error loading filtered schools'
                                    : 'Error loading filtered colleges',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _filteredSchoolsError ?? _filteredCollegesError ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _selectedType == InstitutionType.schools
                                    ? _fetchFilteredSchools
                                    : _fetchFilteredColleges,
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
                    : _filteredInstitutions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  localizations?.translate('no_results') ?? 'No results found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredInstitutions.length,
                            itemBuilder: (context, index) {
                              final institution = _filteredInstitutions[index];
                              return _buildInstitutionCard(institution, localizations);
                            },
                          ),
          ),
        ],
      )
    );
  }

  // Helper method to convert institution name to translation key
  String _getNameKey(String name) {
    // Return name as translation key (convert to lowercase with underscores)
    return name.toLowerCase().replaceAll(' ', '_');
  }

  // Get first character of institution name for dynamic logo
  String _getFirstCharacter(String name) {
    if (name.isEmpty) return '?';
    final trimmed = name.trim();
    return trimmed[0].toUpperCase();
  }

  Widget _buildInstitutionCard(
    Map<String, dynamic> institution,
    AppLocalizations? localizations,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InstitutionDetailsScreen(
                  institution: institution,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Institution Logo - Dynamic (first character)
                Container(
                  width: 78,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryIndigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryIndigo.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getFirstCharacter(
                        institution['institution_name'] as String? ?? 
                        institution['name'] as String? ?? 
                        ''
                      ),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryIndigo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Institution Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations?.translate(_getNameKey(
                          institution['institution_name'] as String? ?? 
                          institution['name'] as String? ?? 
                          ''
                        )) ?? 
                        (institution['institution_name'] as String? ?? 
                         institution['name'] as String? ?? 
                         ''),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${institution['avg_rating'] ?? institution['rating'] ?? 'N/A'} (${institution['total_reviews'] ?? institution['reviews'] ?? 0} ${localizations?.translate('reviews') ?? 'reviews'})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      // School tags (curriculum)
                      if ((institution['type'] == InstitutionType.schools) ||
                          (institution['institution_type'] as String? ?? '').toLowerCase() == 'school')
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: SizedBox(
                            height: 28,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              children: [
                                // Curriculum tags
                                if (institution['curriculum'] != null || institution['curriculum_type'] != null)
                                  ...((institution['curriculum_type'] != null
                                      ? [institution['curriculum_type']]
                                      : (institution['curriculum'] is List
                                          ? (institution['curriculum'] as List)
                                          : [institution['curriculum']]))
                                    .map<Widget>((curriculum) {
                                      final curriculumStr = curriculum.toString();
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryIndigo.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          localizations?.translate(curriculumStr.toLowerCase().replaceAll(' ', '_')) ?? 
                                          curriculumStr,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.primaryIndigo,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList()),
                              ],
                            ),
                          ),
                        ),
                      // College courses (horizontal scroll)
                      if ((institution['type'] == InstitutionType.colleges ||
                           (institution['institution_type'] as String? ?? '').toLowerCase() == 'college') &&
                          institution['courses'] != null &&
                          (institution['courses'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: SizedBox(
                            height: 28,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              children: (institution['courses'] as List)
                                  .map((course) {
                                    final courseName = course is Map 
                                        ? (course['name'] as String? ?? '')
                                        : course.toString();
                                    final translationKey = courseName.toLowerCase().replaceAll(' ', '_');
                                    final translatedName = localizations?.translate(translationKey);
                                    final displayName = (translatedName != null && translatedName != translationKey)
                                        ? translatedName
                                        : courseName.replaceAll('_', ' ');
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryIndigo.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primaryIndigo,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                      // College streams/field of study
                      if ((institution['type'] == InstitutionType.colleges ||
                           (institution['institution_type'] as String? ?? '').toLowerCase() == 'college') &&
                          (institution['streams'] != null || institution['fieldOfStudy'] != null))
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: SizedBox(
                            height: 28,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              children: ((institution['streams'] ?? institution['fieldOfStudy']) as List<String>)
                                  .map((field) => Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryIndigo.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          localizations?.translate(field) ?? field,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.primaryIndigo,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAppliedFiltersChips(AppLocalizations? localizations) {
  final appliedFilters = <Widget>[];

  // Category filter (always show if any filter is applied)
  if (_hasAnyFilterApplied) {
    appliedFilters.add(_buildFilterTag(
      _selectedType == InstitutionType.schools 
          ? localizations?.translate('schools') ?? 'Schools'
          : localizations?.translate('colleges') ?? 'Colleges',
      null, // No delete for category
    ));
  }

  if (_selectedType == InstitutionType.schools) {
    // School filters
    if (_selectedCurriculum != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedCurriculum!) ?? _selectedCurriculum!,
        () {
          setState(() => _selectedCurriculum = null);
          _fetchFilteredSchools(); // Refresh API results
        },
      ));
    }
    if (_selectedGradeLevel != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedGradeLevel!) ?? _selectedGradeLevel!,
        () {
          setState(() => _selectedGradeLevel = null);
          _fetchFilteredSchools(); // Refresh API results
        },
      ));
    }
    if (_selectedGenderType != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedGenderType!) ?? _selectedGenderType!,
        () {
          setState(() => _selectedGenderType = null);
          _fetchFilteredSchools(); // Refresh API results
        },
      ));
    }
    if (_selectedSchoolType != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedSchoolType!) ?? _selectedSchoolType!,
        () {
          setState(() => _selectedSchoolType = null);
          _fetchFilteredSchools(); // Refresh API results
        },
      ));
    }
    if (_selectedCity != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedCity!) ?? _selectedCity!,
        () {
          setState(() => _selectedCity = null);
          _fetchFilteredSchools(); // Refresh API results
        },
      ));
    }
  } else {
    // College filters
    if (_selectedInstitutionType != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedInstitutionType!) ?? _selectedInstitutionType!,
        () {
          setState(() => _selectedInstitutionType = null);
          _fetchFilteredColleges(); // Refresh API results
        },
      ));
    }
    if (_selectedFieldOfStudy != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedFieldOfStudy!) ?? _selectedFieldOfStudy!,
        () {
          setState(() => _selectedFieldOfStudy = null);
          _fetchFilteredColleges(); // Refresh API results
        },
      ));
    }
    if (_selectedDegreeType != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedDegreeType!) ?? _selectedDegreeType!,
        () {
          setState(() => _selectedDegreeType = null);
          _fetchFilteredColleges(); // Refresh API results
        },
      ));
    }
    if (_selectedGenderSystem != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedGenderSystem!) ?? _selectedGenderSystem!,
        () {
          setState(() => _selectedGenderSystem = null);
          _fetchFilteredColleges(); // Refresh API results
        },
      ));
    }
    if (_selectedCollegeCity != null) {
      appliedFilters.add(_buildFilterTag(
        localizations?.translate(_selectedCollegeCity!) ?? _selectedCollegeCity!,
        () {
          setState(() => _selectedCollegeCity = null);
          _fetchFilteredColleges(); // Refresh API results
        },
      ));
    }
  }

  if (appliedFilters.isEmpty) return SizedBox.shrink();

  return Container(
    height: 45,
    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: appliedFilters.length,
      separatorBuilder: (context, index) => SizedBox(width: 8),
      itemBuilder: (context, index) => appliedFilters[index],
    ),
  );
}

// Helper method to create filter tags that match your institution card style
Widget _buildFilterTag(String label, VoidCallback? onDelete) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.primaryIndigo.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppTheme.primaryIndigo.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.primaryIndigo,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (onDelete != null) ...[
          SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              size: 16,
              color: AppTheme.primaryIndigo,
            ),
          ),
        ],
      ],
    ),
  );
}

// Helper getter to check if any filters are applied
bool get _hasAnyFilterApplied {
  if (_selectedType == InstitutionType.schools) {
    return _selectedCurriculum != null ||
        _selectedGradeLevel != null ||
        _selectedGenderType != null ||
        _selectedSchoolType != null ||
        _selectedCity != null;
  } else {
    return _selectedInstitutionType != null ||
        _selectedFieldOfStudy != null ||
        _selectedDegreeType != null ||
        _selectedGenderSystem != null ||
        _selectedCollegeCity != null;
  }
}


}

