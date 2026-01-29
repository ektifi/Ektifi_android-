import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';

class FiltersScreen extends StatefulWidget {
  final InstitutionType selectedType;
  // School filters
  final String? selectedCurriculum;
  final String? selectedGradeLevel;
  final String? selectedGenderType;
  final String? selectedSchoolType;
  final String? selectedCity;
  // College filters
  final String? selectedInstitutionType;
  final String? selectedFieldOfStudy;
  final String? selectedDegreeType;
  final String? selectedGenderSystem;
  final String? selectedCollegeCity;
  // Options
  final List<String> curriculumOptions;
  final List<String> gradeLevelOptions;
  final List<String> genderTypeOptions;
  final List<String> schoolTypeOptions;
  final List<String> cityOptions;
  final List<String> institutionTypeOptions;
  final List<String> fieldOfStudyOptions;
  final List<String> degreeTypeOptions;
  final List<String> genderSystemOptions;
  final List<String> collegeCityOptions;

  const FiltersScreen({
    super.key,
    required this.selectedType,
    this.selectedCurriculum,
    this.selectedGradeLevel,
    this.selectedGenderType,
    this.selectedSchoolType,
    this.selectedCity,
    this.selectedInstitutionType,
    this.selectedFieldOfStudy,
    this.selectedDegreeType,
    this.selectedGenderSystem,
    this.selectedCollegeCity,
    required this.curriculumOptions,
    required this.gradeLevelOptions,
    required this.genderTypeOptions,
    required this.schoolTypeOptions,
    required this.cityOptions,
    required this.institutionTypeOptions,
    required this.fieldOfStudyOptions,
    required this.degreeTypeOptions,
    required this.genderSystemOptions,
    required this.collegeCityOptions,
  });

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late InstitutionType _selectedType;
  late String? _selectedCurriculum;
  late String? _selectedGradeLevel;
  late String? _selectedGenderType;
  late String? _selectedSchoolType;
  late String? _selectedCity;
  late String? _selectedInstitutionType;
  late String? _selectedFieldOfStudy;
  late String? _selectedDegreeType;
  late String? _selectedGenderSystem;
  late String? _selectedCollegeCity;

  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedCurriculum = widget.selectedCurriculum;
    _selectedGradeLevel = widget.selectedGradeLevel;
    _selectedGenderType = widget.selectedGenderType;
    _selectedSchoolType = widget.selectedSchoolType;
    _selectedCity = widget.selectedCity;
    _selectedInstitutionType = widget.selectedInstitutionType;
    _selectedFieldOfStudy = widget.selectedFieldOfStudy;
    _selectedDegreeType = widget.selectedDegreeType;
    _selectedGenderSystem = widget.selectedGenderSystem;
    _selectedCollegeCity = widget.selectedCollegeCity;

    // Set initial category
    _selectedCategory = 'category';
  }

  List<Map<String, dynamic>> get _filterCategories {
    final baseCategories = [
      {
        'key': 'category',
        'label': 'category',
      },
    ];
    
    if (_selectedType == InstitutionType.schools) {
      return [
        ...baseCategories,
        {
          'key': 'curriculum',
          'label': 'curriculum',
        },
        {
          'key': 'grade_level',
          'label': 'grade_level',
        },
        {
          'key': 'gender_type',
          'label': 'gender_type',
        },
        {
          'key': 'school_type',
          'label': 'school_type',
        },
        {
          'key': 'city',
          'label': 'city',
        },
      ];
    } else {
      return [
        ...baseCategories,
        {
          'key': 'institution_type',
          'label': 'institution_type',
        },
        {
          'key': 'field_of_study',
          'label': 'field_of_study',
        },
        {
          'key': 'degree_type',
          'label': 'degree_type',
        },
        {
          'key': 'gender_system',
          'label': 'gender_system',
        },
        {
          'key': 'city',
          'label': 'city',
        },
      ];
    }
  }

  List<String> get _currentOptions {
    switch (_selectedCategory) {
      case 'category':
        return ['schools', 'colleges'];
      case 'curriculum':
        return widget.curriculumOptions;
      case 'grade_level':
        return widget.gradeLevelOptions;
      case 'gender_type':
        return widget.genderTypeOptions;
      case 'school_type':
        return widget.schoolTypeOptions;
      case 'city':
        return _selectedType == InstitutionType.schools
            ? widget.cityOptions
            : widget.collegeCityOptions;
      case 'institution_type':
        return widget.institutionTypeOptions;
      case 'field_of_study':
        return widget.fieldOfStudyOptions;
      case 'degree_type':
        return widget.degreeTypeOptions;
      case 'gender_system':
        return widget.genderSystemOptions;
      default:
        return [];
    }
  }

  String? get _currentSelectedValue {
    switch (_selectedCategory) {
      case 'category':
        return _selectedType == InstitutionType.schools ? 'schools' : 'colleges';
      case 'curriculum':
        return _selectedCurriculum;
      case 'grade_level':
        return _selectedGradeLevel;
      case 'gender_type':
        return _selectedGenderType;
      case 'school_type':
        return _selectedSchoolType;
      case 'city':
        return _selectedType == InstitutionType.schools
            ? _selectedCity
            : _selectedCollegeCity;
      case 'institution_type':
        return _selectedInstitutionType;
      case 'field_of_study':
        return _selectedFieldOfStudy;
      case 'degree_type':
        return _selectedDegreeType;
      case 'gender_system':
        return _selectedGenderSystem;
      default:
        return null;
    }
  }

  void _setSelectedValue(String? value) {
    setState(() {
      switch (_selectedCategory) {
        case 'category':
          if (value == 'schools') {
            _selectedType = InstitutionType.schools;
            _selectedCategory = 'curriculum'; // Switch to first school filter
          } else if (value == 'colleges') {
            _selectedType = InstitutionType.colleges;
            _selectedCategory = 'institution_type'; // Switch to first college filter
          }
          break;
        case 'curriculum':
          _selectedCurriculum = value;
          break;
        case 'grade_level':
          _selectedGradeLevel = value;
          break;
        case 'gender_type':
          _selectedGenderType = value;
          break;
        case 'school_type':
          _selectedSchoolType = value;
          break;
        case 'city':
          if (_selectedType == InstitutionType.schools) {
            _selectedCity = value;
          } else {
            _selectedCollegeCity = value;
          }
          break;
        case 'institution_type':
          _selectedInstitutionType = value;
          break;
        case 'field_of_study':
          _selectedFieldOfStudy = value;
          break;
        case 'degree_type':
          _selectedDegreeType = value;
          break;
        case 'gender_system':
          _selectedGenderSystem = value;
          break;
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCurriculum = null;
      _selectedGradeLevel = null;
      _selectedGenderType = null;
      _selectedSchoolType = null;
      _selectedCity = null;
      _selectedInstitutionType = null;
      _selectedFieldOfStudy = null;
      _selectedDegreeType = null;
      _selectedGenderSystem = null;
      _selectedCollegeCity = null;
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop({
      'selectedType': _selectedType,
      'selectedCurriculum': _selectedCurriculum,
      'selectedGradeLevel': _selectedGradeLevel,
      'selectedGenderType': _selectedGenderType,
      'selectedSchoolType': _selectedSchoolType,
      'selectedCity': _selectedCity,
      'selectedInstitutionType': _selectedInstitutionType,
      'selectedFieldOfStudy': _selectedFieldOfStudy,
      'selectedDegreeType': _selectedDegreeType,
      'selectedGenderSystem': _selectedGenderSystem,
      'selectedCollegeCity': _selectedCollegeCity,
    });
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
        title: Text(
          localizations?.translate('filters') ?? 'Filters',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              localizations?.translate('clear_all') ?? 'Clear all',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Column - Filter Categories
          Container(
            width: 120,
            color: Colors.grey[100],
            child: ListView.builder(
              itemCount: _filterCategories.length,
              itemBuilder: (context, index) {
                final category = _filterCategories[index];
                final isSelected = _selectedCategory == category['key'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['key'] as String;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    color: isSelected ? Colors.grey[200] : Colors.transparent,
                    child: Text(
                      localizations?.translate(category['label'] as String) ??
                          category['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Right Column - Filter Options
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _currentOptions.length,
                itemBuilder: (context, index) {
                  final option = _currentOptions[index];
                  final isSelected = _currentSelectedValue == option;
                  return InkWell(
                    onTap: () {
                      _setSelectedValue(isSelected ? null : option);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizations?.translate(option) ?? option,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.accentCyan,
                              size: 24,
                            )
                          else
                            Icon(
                              Icons.circle_outlined,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryIndigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              localizations?.translate('apply') ?? 'Apply',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

