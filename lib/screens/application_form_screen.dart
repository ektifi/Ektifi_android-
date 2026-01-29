import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../api/api_service.dart';

class ApplicationFormScreen extends StatefulWidget {
  final Map<String, dynamic> institution;
  final bool isSchool;
  final int? applicationId; // Optional: if provided, we're editing an existing application

  const ApplicationFormScreen({
    super.key,
    required this.institution,
    required this.isSchool,
    this.applicationId,
  });

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0 = initial, 1-3 = steps

  // Initial Screen Fields (Step 0)
  final _fullNameController = TextEditingController();
  final _arabicNameController = TextEditingController();
  String? _selectedGender;
  final _dateOfBirthController = TextEditingController();
  String? _selectedCountry;
  String? _selectedIdentification; // citizen, resident, international
  
  // Dynamic identification fields (Student)
  final _nationalIdController = TextEditingController();
  final _iqamaNumberController = TextEditingController();
  final _iqamaExpiryDateController = TextEditingController();
  final _passportNumberController = TextEditingController();
  
  // Contact and Address
  final _primaryNumberController = TextEditingController();
  final _secondaryNumberController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();

  // Step 1: Parent Details
  final _fatherNameController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  String? _fatherIdentification; // citizen, resident, international
  
  // Dynamic identification fields (Father)
  final _fatherNationalIdController = TextEditingController();
  final _fatherIqamaNumberController = TextEditingController();
  final _fatherIqamaExpiryDateController = TextEditingController();
  final _fatherPassportNumberController = TextEditingController();
  
  final _fatherNumberController = TextEditingController();
  
  final _motherNameController = TextEditingController();
  final _motherOccupationController = TextEditingController();

  // Step 2: Academic Information
  final _previousQualificationController = TextEditingController();
  final _yearOfCompletionController = TextEditingController();
  final _percentageOrCgpaController = TextEditingController();
  String? _currentAcademicsSelection;
  String? _selectedProgramCourse;
  String? _selectedDepartment;
  final _institutionNameController = TextEditingController();
  final _institutionAddressController = TextEditingController();

  // Step 3: Upload Documents
  String? _uploadPhotoPath;
  String? _uploadIdIqamaPath;
  String? _uploadMarksheetPath;

  final AuthService _authService = AuthService();
  bool _isSubmitting = false;
  bool _isLoadingApplication = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.applicationId != null;
    if (_isEditMode && widget.applicationId != null) {
      _loadApplicationData();
    }
  }

  Future<void> _loadApplicationData() async {
    if (widget.applicationId == null) return;

    setState(() => _isLoadingApplication = true);

    try {
      final token = await _authService.getToken();
      if (token == null) {
        CustomSnackBar.showError(context, 'Please login to view application');
        Navigator.of(context).pop();
        return;
      }

      final applicationData = await ApiService.fetchApplicationById(
        applicationId: widget.applicationId!,
        token: token,
      );

      // Pre-fill all form fields with application data
      _prefillFormFields(applicationData);

      setState(() => _isLoadingApplication = false);
    } catch (e) {
      setState(() => _isLoadingApplication = false);
      CustomSnackBar.showError(context, 'Failed to load application: ${e.toString()}');
      Navigator.of(context).pop();
    }
  }

  void _prefillFormFields(Map<String, dynamic> data) {
    // Step 0: Personal and Identity Details
    _fullNameController.text = data['full_name'] as String? ?? '';
    _arabicNameController.text = data['arabic_name'] as String? ?? '';
    _selectedGender = data['gender'] as String?;
    if (data['date_of_birth'] != null) {
      final dob = _parseDateFromAPI(data['date_of_birth'].toString());
      if (dob != null) {
        _dateOfBirthController.text = '${dob.day}/${dob.month}/${dob.year}';
      }
    }
    _selectedCountry = data['country'] as String?;

    // Determine identification type and fill fields
    if (data['identification'] != null && (data['identification'] as String).isNotEmpty) {
      _selectedIdentification = 'citizen';
      _nationalIdController.text = data['identification'] as String? ?? '';
    } else if (data['iqama_number'] != null && (data['iqama_number'] as String).isNotEmpty) {
      _selectedIdentification = 'resident';
      _iqamaNumberController.text = data['iqama_number'] as String? ?? '';
      if (data['iqama_expiry_date'] != null) {
        final expiry = _parseDateFromAPI(data['iqama_expiry_date'].toString());
        if (expiry != null) {
          _iqamaExpiryDateController.text = '${expiry.day}/${expiry.month}/${expiry.year}';
        }
      }
    } else if (data['passport_number'] != null && (data['passport_number'] as String).isNotEmpty) {
      _selectedIdentification = 'international';
      _passportNumberController.text = data['passport_number'] as String? ?? '';
    }

    _primaryNumberController.text = data['primary_number'] as String? ?? '';
    _secondaryNumberController.text = data['secondary_number'] as String? ?? '';
    _address1Controller.text = data['address_1'] as String? ?? '';
    _address2Controller.text = data['address_2'] as String? ?? '';

    // Step 1: Parent Details
    _fatherNameController.text = data['father_name'] as String? ?? '';
    _fatherOccupationController.text = data['father_occupation'] as String? ?? '';
    
    // Determine parent identification type
    if (data['parent_national_id'] != null && (data['parent_national_id'] as String).isNotEmpty) {
      _fatherIdentification = 'citizen';
      _fatherNationalIdController.text = data['parent_national_id'] as String? ?? '';
    } else if (data['parent_iqama_number'] != null && (data['parent_iqama_number'] as String).isNotEmpty) {
      _fatherIdentification = 'resident';
      _fatherIqamaNumberController.text = data['parent_iqama_number'] as String? ?? '';
      if (data['parent_iqama_expiry'] != null) {
        final expiry = _parseDateFromAPI(data['parent_iqama_expiry'].toString());
        if (expiry != null) {
          _fatherIqamaExpiryDateController.text = '${expiry.day}/${expiry.month}/${expiry.year}';
        }
      }
    } else if (data['parent_passport_number'] != null && (data['parent_passport_number'] as String).isNotEmpty) {
      _fatherIdentification = 'international';
      _fatherPassportNumberController.text = data['parent_passport_number'] as String? ?? '';
    } else if (data['parent_identification'] != null && (data['parent_identification'] as String).isNotEmpty) {
      // Fallback: if parent_identification exists but no specific field, assume citizen
      _fatherIdentification = 'citizen';
      _fatherNationalIdController.text = data['parent_identification'] as String? ?? '';
    }

    _fatherNumberController.text = data['parent_number'] as String? ?? '';
    _motherNameController.text = data['mother_name'] as String? ?? '';
    _motherOccupationController.text = data['mother_occupation'] as String? ?? '';

    // Step 2: Academic Information
    _previousQualificationController.text = data['previous_qualification'] as String? ?? '';
    if (data['year_of_completion'] != null) {
      final year = _parseDateFromAPI(data['year_of_completion'].toString());
      if (year != null) {
        _yearOfCompletionController.text = '${year.year}';
      } else {
        _yearOfCompletionController.text = data['year_of_completion'].toString();
      }
    }
    _percentageOrCgpaController.text = data['percentage_or_cgpa'] as String? ?? '';
    _currentAcademicsSelection = data['course'] as String?;
    _selectedProgramCourse = data['program_course'] as String?;
    _selectedDepartment = data['department'] as String?;
    _institutionNameController.text = data['previous_institution_name'] as String? ?? '';
    _institutionAddressController.text = data['previous_institution_address'] as String? ?? '';

    // Step 3: Documents (paths are stored but not displayed in UI)
    _uploadPhotoPath = data['document_photo_upload'] as String?;
    _uploadIdIqamaPath = data['identification_photo_upload'] as String?;
    _uploadMarksheetPath = data['previous_marksheet'] as String?;

    setState(() {});
  }

  DateTime? _parseDateFromAPI(String dateString) {
    try {
      // Handle ISO format: "2010-01-10T00:00:00.000000Z"
      if (dateString.contains('T')) {
        return DateTime.parse(dateString);
      }
      // Handle space format: "2026-01-10 03:23:46"
      if (dateString.contains(' ')) {
        return DateTime.parse(dateString.replaceAll(' ', 'T'));
      }
      // Handle date only: "2010-01-10"
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $dateString - $e');
      return null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _arabicNameController.dispose();
    _dateOfBirthController.dispose();
    _nationalIdController.dispose();
    _iqamaNumberController.dispose();
    _iqamaExpiryDateController.dispose();
    _passportNumberController.dispose();
    _primaryNumberController.dispose();
    _secondaryNumberController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _fatherNameController.dispose();
    _fatherOccupationController.dispose();
    _fatherNationalIdController.dispose();
    _fatherIqamaNumberController.dispose();
    _fatherIqamaExpiryDateController.dispose();
    _fatherPassportNumberController.dispose();
    _fatherNumberController.dispose();
    _motherNameController.dispose();
    _motherOccupationController.dispose();
    _previousQualificationController.dispose();
    _yearOfCompletionController.dispose();
    _percentageOrCgpaController.dispose();
    _institutionNameController.dispose();
    _institutionAddressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate initial screen
      if (!_validateInitialStep()) {
        return;
      }
      setState(() => _currentStep = 1);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentStep < 3) {
      // Validate current step
      if (!_validateCurrentStep()) {
        return;
      }
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
  
  bool _validateInitialStep() {
    // Required fields: full_name, arabic_name, gender, date_of_birth, country, identification
    if (_fullNameController.text.isEmpty ||
        _arabicNameController.text.isEmpty ||
        _selectedGender == null ||
        _dateOfBirthController.text.isEmpty ||
        _selectedCountry == null ||
        _selectedIdentification == null) {
      CustomSnackBar.showError(context, 'Please fill all required fields');
      return false;
    }
    
    // Validate identification fields based on selection
    if (_selectedIdentification == 'citizen') {
      if (_nationalIdController.text.isEmpty) {
        CustomSnackBar.showError(context, 'Please enter National ID');
        return false;
      }
    } else if (_selectedIdentification == 'resident') {
      if (_iqamaNumberController.text.isEmpty || _iqamaExpiryDateController.text.isEmpty) {
        CustomSnackBar.showError(context, 'Please enter Iqama Number and Expiry Date');
        return false;
      }
    } else if (_selectedIdentification == 'international') {
      if (_passportNumberController.text.isEmpty) {
        CustomSnackBar.showError(context, 'Please enter Passport Number');
        return false;
      }
    }
    
    // Validate contact fields
    if (_primaryNumberController.text.isEmpty || _address1Controller.text.isEmpty) {
      CustomSnackBar.showError(context, 'Please fill primary number and address');
      return false;
    }
    
    return true;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 1:
        // Step 1: Parent Details
        if (_fatherNameController.text.isEmpty ||
            _fatherOccupationController.text.isEmpty ||
            _fatherIdentification == null ||
            _fatherNumberController.text.isEmpty ||
            _motherNameController.text.isEmpty ||
            _motherOccupationController.text.isEmpty) {
          CustomSnackBar.showError(context, 'Please fill all required fields');
          return false;
        }
        
        // Validate parent identification fields
        if (_fatherIdentification == 'citizen') {
          if (_fatherNationalIdController.text.isEmpty) {
            CustomSnackBar.showError(context, 'Please enter Parent\'s National ID');
            return false;
          }
        } else if (_fatherIdentification == 'resident') {
          if (_fatherIqamaNumberController.text.isEmpty || _fatherIqamaExpiryDateController.text.isEmpty) {
            CustomSnackBar.showError(context, 'Please enter Parent\'s Iqama Number and Expiry Date');
            return false;
          }
        } else if (_fatherIdentification == 'international') {
          if (_fatherPassportNumberController.text.isEmpty) {
            CustomSnackBar.showError(context, 'Please enter Parent\'s Passport Number');
            return false;
          }
        }
        break;
      case 2:
        // Step 2: Academic Information
        if (_previousQualificationController.text.isEmpty ||
            _yearOfCompletionController.text.isEmpty ||
            _percentageOrCgpaController.text.isEmpty ||
            _currentAcademicsSelection == null ||
            _institutionNameController.text.isEmpty ||
            _institutionAddressController.text.isEmpty) {
          CustomSnackBar.showError(context, 'Please fill all required fields');
          return false;
        }
        
        // If not school, validate program course and department
        if (!widget.isSchool) {
          if (_selectedProgramCourse == null || _selectedDepartment == null) {
            CustomSnackBar.showError(context, 'Please select Program Course and Department');
            return false;
          }
        }
        break;
    }
    return true;
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_validateCurrentStep()) {
        return;
      }

    setState(() => _isSubmitting = true);

    try {
      final token = await _authService.getToken();
      if (token == null) {
        CustomSnackBar.showError(context, 'Please login to ${_isEditMode ? 'update' : 'submit'} application');
        setState(() => _isSubmitting = false);
        return;
      }

      final institutionId = widget.institution['id'];
      if (institutionId == null) {
        CustomSnackBar.showError(context, 'Institution ID is missing');
        setState(() => _isSubmitting = false);
        return;
      }

      // Build identification value based on type
      String identificationValue = '';
      if (_selectedIdentification == 'citizen') {
        identificationValue = _nationalIdController.text.trim();
      } else if (_selectedIdentification == 'resident') {
        identificationValue = _iqamaNumberController.text.trim();
      } else if (_selectedIdentification == 'international') {
        identificationValue = _passportNumberController.text.trim();
      }

      // Build parent identification value based on type
      String parentIdentificationValue = '';
      if (_fatherIdentification == 'citizen') {
        parentIdentificationValue = _fatherNationalIdController.text.trim();
      } else if (_fatherIdentification == 'resident') {
        parentIdentificationValue = _fatherIqamaNumberController.text.trim();
      } else if (_fatherIdentification == 'international') {
        parentIdentificationValue = _fatherPassportNumberController.text.trim();
      }

      final payload = <String, dynamic>{
        'full_name': _fullNameController.text.trim(),
        'arabic_name': _arabicNameController.text.trim(),
        'gender': _selectedGender ?? '',
        'date_of_birth': _formatDateForAPI(_dateOfBirthController.text),
        'country': _selectedCountry ?? '',
        'identification': identificationValue,
        'primary_number': _primaryNumberController.text.trim(),
        'secondary_number': _secondaryNumberController.text.trim(),
        'address_1': _address1Controller.text.trim(),
        'address_2': _address2Controller.text.trim(),
        'father_name': _fatherNameController.text.trim(),
        'father_occupation': _fatherOccupationController.text.trim(),
        'parent_identification': parentIdentificationValue,
        'parent_number': _fatherNumberController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'mother_occupation': _motherOccupationController.text.trim(),
        'previous_qualification': _previousQualificationController.text.trim(),
        'year_of_completion': _formatYearOfCompletion(_yearOfCompletionController.text.trim()),
        'percentage_or_cgpa': _percentageOrCgpaController.text.trim(),
        'course': _currentAcademicsSelection ?? '',
        'previous_institution_name': _institutionNameController.text.trim(),
        'previous_institution_address': _institutionAddressController.text.trim(),
        'document_photo_upload': _uploadPhotoPath ?? '',
        'identification_photo_upload': _uploadIdIqamaPath ?? '',
        'previous_marksheet': _uploadMarksheetPath ?? '',
      };

      // Add identification-specific fields based on selection
      if (_selectedIdentification == 'citizen') {
        payload['national_id'] = _nationalIdController.text.trim();
      } else if (_selectedIdentification == 'resident') {
        payload['iqama_number'] = _iqamaNumberController.text.trim();
        payload['iqama_expiry_date'] = _formatDateForAPI(_iqamaExpiryDateController.text);
      } else if (_selectedIdentification == 'international') {
        payload['passport_number'] = _passportNumberController.text.trim();
      }

      // Add parent identification-specific fields (all fields based on API spec)
      if (_fatherIdentification == 'citizen') {
        payload['parent_national_id'] = _fatherNationalIdController.text.trim();
      } else if (_fatherIdentification == 'resident') {
        payload['parent_iqama_number'] = _fatherIqamaNumberController.text.trim();
        payload['parent_iqama_expiry'] = _formatDateForAPI(_fatherIqamaExpiryDateController.text);
      } else if (_fatherIdentification == 'international') {
        payload['parent_passport_number'] = _fatherPassportNumberController.text.trim();
      }

      // Add program course and department for colleges only
      if (!widget.isSchool) {
        payload['program_course'] = _selectedProgramCourse ?? '';
        payload['department'] = _selectedDepartment ?? '';
      }

      if (_isEditMode && widget.applicationId != null) {
        // Update existing application
        final result = await ApiService.updateApplication(
          applicationId: widget.applicationId!,
          payload: payload,
          token: token,
        );

        setState(() => _isSubmitting = false);

        if (result['status'] == true) {
          CustomSnackBar.showSuccess(
            context,
            result['message'] as String? ?? 'Application updated successfully!',
          );
          Navigator.of(context).pop();
        } else {
          CustomSnackBar.showError(
            context,
            result['message'] as String? ?? 'Failed to update application',
          );
        }
      } else {
        // Create new application
        final institutionIdStr = institutionId is int ? institutionId.toString() : institutionId.toString();
        final apiUrl = '${ApiService.baseUrl}/institutions/$institutionIdStr/applications';

        print('=== APPLICATION SUBMIT ===');
        print('URL: $apiUrl');
        print('Payload: ${json.encode(payload)}');

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(payload),
        );

        setState(() => _isSubmitting = false);

        print('Response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          if (jsonData['status'] == true) {
            CustomSnackBar.showSuccess(
              context,
              jsonData['message'] as String? ?? 'Application submitted successfully!',
            );
            Navigator.of(context).pop();
          } else {
            CustomSnackBar.showError(
              context,
              jsonData['message'] as String? ?? 'Failed to submit application',
            );
          }
        } else {
          try {
            final errorData = json.decode(response.body) as Map<String, dynamic>;
            CustomSnackBar.showError(
              context,
              errorData['message'] as String? ?? 'Failed to submit application',
            );
          } catch (e) {
            CustomSnackBar.showError(
              context,
              'Failed to submit application: ${response.statusCode}',
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      CustomSnackBar.showError(context, 'Error: ${e.toString()}');
    }
  }

  String _formatDateForAPI(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return dateString;
  }

  String _formatYearOfCompletion(String yearString) {
    if (yearString.isEmpty) return '';
    try {
      // If it's just a year (4 digits), convert to date format (year-06-15)
      if (yearString.length == 4 && RegExp(r'^\d{4}$').hasMatch(yearString)) {
        return '$yearString-06-15';
      }
      // If it's already in date format, use it
      if (yearString.contains('-')) {
        return yearString;
      }
      // Try to parse as date string with / separator
      final parts = yearString.split('/');
      if (parts.length == 3) {
        return _formatDateForAPI(yearString);
      }
    } catch (e) {
      print('Error formatting year of completion: $e');
    }
    return yearString;
  }

  double _getProgress() {
    if (_currentStep == 0) return 0.0;
    return _currentStep / 3.0; // 0 = initial, 1-3 = steps
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Show loading indicator while fetching application data
    if (_isLoadingApplication) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentStep == 0
          ? AppBar(
              backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
            )
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousStep,
              ),
              title: _currentStep > 0
                  ? Column(
                      children: [
                        Text(
                          'Step $_currentStep of 3',
          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
          ),
        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _getProgress(),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          minHeight: 4,
                        ),
                      ],
                    )
                  : null,
              centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
          children: [
          _buildInitialScreen(localizations),
          _buildStep1ParentDetails(localizations),
          _buildStep2AcademicInfo(localizations),
          _buildStep3UploadDocuments(localizations),
        ],
      ),
    );
  }

  Widget _buildInitialScreen(AppLocalizations? localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          const SizedBox(height: 20),
          Text(
            'College Application',
            style: const TextStyle(
              fontSize: 24,
                                fontWeight: FontWeight.w600,
              color: Colors.black87,
                      ),
                    ),
          const SizedBox(height: 32),
          // Required fields
          _buildTextField(_fullNameController, 'Full Name', isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_arabicNameController, 'Arabic Name', isRequired: true),
          const SizedBox(height: 16),
          _buildGenderRadioButtons(),
          const SizedBox(height: 16),
          _buildDateField(_dateOfBirthController, 'Date of Birth', isRequired: true),
          const SizedBox(height: 16),
          _buildCountryDropdown(),
          const SizedBox(height: 16),
          _buildIdentificationDropdown('Identification'),
          if (_selectedIdentification != null) ...[
            const SizedBox(height: 16),
            // Dynamic identification fields based on selection
            _buildDynamicIdentificationFields(),
                      ],
          const SizedBox(height: 16),
          _buildTextField(_primaryNumberController, 'Primary Number', keyboardType: TextInputType.phone, isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_secondaryNumberController, 'Secondary Number', keyboardType: TextInputType.phone, isRequired: false),
          const SizedBox(height: 16),
          _buildTextField(_address1Controller, 'Address 1', isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_address2Controller, 'Address 2', isRequired: false),
          const SizedBox(height: 40),
          _buildGreenButton('Continue', _nextStep),
        ],
      ),
    );
  }
  
  Widget _buildDynamicIdentificationFields() {
    if (_selectedIdentification == 'citizen') {
      return _buildTextField(_nationalIdController, 'National ID', isRequired: true);
    } else if (_selectedIdentification == 'resident') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(_iqamaNumberController, 'Iqama Number', isRequired: true),
          const SizedBox(height: 16),
          _buildDateField(_iqamaExpiryDateController, 'Iqama Expiry Date', isRequired: true),
        ],
      );
    } else if (_selectedIdentification == 'international') {
      return _buildTextField(_passportNumberController, 'Passport Number', isRequired: true);
    }
    return const SizedBox.shrink();
  }
  
  Widget _buildDynamicFatherIdentificationFields() {
    if (_fatherIdentification == 'citizen') {
      return _buildTextField(_fatherNationalIdController, 'Parent\'s National ID', isRequired: true);
    } else if (_fatherIdentification == 'resident') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(_fatherIqamaNumberController, 'Parent\'s Iqama Number', isRequired: true),
                      const SizedBox(height: 16),
          _buildDateField(_fatherIqamaExpiryDateController, 'Parent\'s Iqama Expiry Date', isRequired: true),
        ],
      );
    } else if (_fatherIdentification == 'international') {
      return _buildTextField(_fatherPassportNumberController, 'Parent\'s Passport Number', isRequired: true);
    }
    return const SizedBox.shrink();
  }

  Widget _buildStep1ParentDetails(AppLocalizations? localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Parent Details'),
          const SizedBox(height: 24),
          // Father Section
          Text(
            'Father Details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(_fatherNameController, 'Father Name', isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_fatherOccupationController, 'Father Occupation', isRequired: true),
          const SizedBox(height: 16),
          _buildIdentificationDropdown('Parent Identification', isFather: true),
          if (_fatherIdentification != null) ...[
            const SizedBox(height: 16),
            _buildDynamicFatherIdentificationFields(),
          ],
          const SizedBox(height: 16),
          _buildTextField(_fatherNumberController, 'Parent Number', keyboardType: TextInputType.phone, isRequired: true),
          const SizedBox(height: 24),
          // Mother Section
          Text(
            'Mother Details',
                      style: const TextStyle(
              fontSize: 18,
                        fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(_motherNameController, 'Mother Name', isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_motherOccupationController, 'Mother Occupation', isRequired: true),
          const SizedBox(height: 40),
          _buildGreenButton('Continue', _nextStep),
        ],
      ),
    );
  }

  Widget _buildStep2AcademicInfo(AppLocalizations? localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Academic Information'),
          const SizedBox(height: 24),
          _buildTextField(_previousQualificationController, 'Previous Qualification', isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_yearOfCompletionController, 'Year of Completion', keyboardType: TextInputType.number, isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_percentageOrCgpaController, 'Percentage or CGPA', keyboardType: TextInputType.number, isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_institutionNameController, 'Institution Name (School/College)', isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(_institutionAddressController, 'Institution Address', isRequired: true),
          const SizedBox(height: 16),
          _buildCurrentAcademicsSelectionDropdown(),
          const SizedBox(height: 16),
          // Show program courses dropdown only for colleges (not schools)
          if (!widget.isSchool) ...[
            _buildProgramCourseDropdown(),
            const SizedBox(height: 16),
            if (_selectedProgramCourse != null) ...[
              _buildDepartmentDropdown(),
              const SizedBox(height: 16),
          ],
          ],
          const SizedBox(height: 40),
          _buildGreenButton('Continue', _nextStep),
        ],
      ),
    );
  }

  Widget _buildStep3UploadDocuments(AppLocalizations? localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Upload Documents'),
          const SizedBox(height: 24),
          _buildUploadButton('Upload Photo', Icons.camera_alt, () {
            setState(() => _uploadPhotoPath = 'photo.jpg');
          }),
          const SizedBox(height: 16),
          _buildUploadButton('Upload Identification Document', Icons.credit_card, () {
            setState(() => _uploadIdIqamaPath = 'identification_document.jpg');
          }),
          const SizedBox(height: 16),
          _buildUploadButton('Upload Marksheet', Icons.description, () {
            setState(() => _uploadMarksheetPath = 'marksheet.pdf');
          }),
          const SizedBox(height: 16),
          Text(
            'You can upload remaining documents later',
            style: TextStyle(
                        fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          _buildGreenButton(
            _isEditMode ? 'Update Application' : 'Submit Application',
            _submitApplication,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryIndigo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
                                fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
          ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, {bool isRequired = false}) {
    return TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
          ),
        suffixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryIndigo),
        ),
        onTap: () => _selectDate(context, controller),
    );
  }

  Widget _buildGenderRadioButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender *',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Male'),
                value: 'Male',
                groupValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Female'),
                value: 'Female',
                groupValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
      ),
      ],
    );
  }


  Widget _buildCountryDropdown() {
    final countries = ['Saudi Arabia', 'India', 'Pakistan', 'Bangladesh', 'Egypt', 'Philippines', 'United States', 'United Kingdom', 'Canada', 'Australia', 'Other'];
    
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      decoration: InputDecoration(
        labelText: 'Country *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
        ),
        suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryIndigo),
      ),
      items: countries.map((country) {
        return DropdownMenuItem(
          value: country,
          child: Text(country),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCountry = value),
    );
  }

  Widget _buildIdentificationDropdown(String label, {bool isFather = false}) {
    final identificationTypes = ['citizen', 'resident', 'international'];
    
    return DropdownButtonFormField<String>(
      value: isFather ? _fatherIdentification : _selectedIdentification,
        decoration: InputDecoration(
        labelText: '$label *',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
          ),
        suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryIndigo),
        ),
      items: identificationTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type[0].toUpperCase() + type.substring(1)), // Capitalize first letter
          );
        }).toList(),
      onChanged: (value) {
        setState(() {
          if (isFather) {
            _fatherIdentification = value;
            // Clear previous identification fields when selection changes
            _fatherNationalIdController.clear();
            _fatherIqamaNumberController.clear();
            _fatherIqamaExpiryDateController.clear();
            _fatherPassportNumberController.clear();
          } else {
            _selectedIdentification = value;
            // Clear previous identification fields when selection changes
            _nationalIdController.clear();
            _iqamaNumberController.clear();
            _iqamaExpiryDateController.clear();
            _passportNumberController.clear();
          }
        });
      },
    );
  }

  Widget _buildCurrentAcademicsSelectionDropdown() {
    final selections = ['Diploma', 'Bachelor\'s Degree', 'Master\'s Degree', 'PhD', 'Other'];
    
    return DropdownButtonFormField<String>(
      value: _currentAcademicsSelection,
      decoration: InputDecoration(
        labelText: 'Current Academics Selection *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
        ),
        suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryIndigo),
      ),
      items: selections.map((selection) {
        return DropdownMenuItem(
          value: selection,
          child: Text(selection),
        );
      }).toList(),
      onChanged: (value) => setState(() => _currentAcademicsSelection = value),
    );
  }

  List<String> _getDepartmentsForCourse(String? course) {
    if (course == null) return [];
    
    switch (course.toLowerCase()) {
      case 'engineering':
        return ['IT', 'MECH', 'CIVIL', 'ECE', 'EEE', 'AUTO'];
      case 'degree':
        return ['Arts', 'BS', 'BA', 'BSc', 'BCom'];
      case 'post graduation':
      case 'postgraduate':
        return ['MTech', 'CD', 'MCA', 'MBA', 'MSc'];
      default:
        return [];
    }
  }

  Widget _buildProgramCourseDropdown() {
    // Remove "High School" from options as per requirement
    final programCourses = ['Engineering', 'Degree', 'Post Graduation'];
    
    return DropdownButtonFormField<String>(
      value: _selectedProgramCourse,
      decoration: InputDecoration(
        labelText: 'Program Course *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
        ),
        suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryIndigo),
      ),
      items: programCourses.map((course) {
        return DropdownMenuItem(
          value: course,
          child: Text(course),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProgramCourse = value;
          _selectedDepartment = null; // Reset department when course changes
        });
      },
    );
  }

  Widget _buildDepartmentDropdown() {
    final departments = _getDepartmentsForCourse(_selectedProgramCourse);
    
    if (departments.isEmpty) return const SizedBox.shrink();
    
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      decoration: InputDecoration(
        labelText: 'Department *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryIndigo, width: 2),
        ),
        suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryIndigo),
      ),
      items: departments.map((dept) {
        return DropdownMenuItem(
          value: dept,
          child: Text(dept),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedDepartment = value),
    );
  }


  Widget _buildUploadButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
            Icon(icon, color: AppTheme.primaryIndigo, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                label,
                style: const TextStyle(
                    fontSize: 16,
                  fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildGreenButton(String text, VoidCallback onPressed, {bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                    style: const TextStyle(
                      fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                    ),
                  ),
      ),
    );
  }
}
