import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_snackbar.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../api/login_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_navigation_screen.dart';
import '../subscription_plan_screen.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final String mobileNumber;
  final String? fullName;
  final String? email;
  final String? password;

  const StudentRegistrationScreen({
    super.key,
    required this.mobileNumber,
    this.fullName,
    this.email,
    this.password,
  });

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _currentGradeController = TextEditingController();
  final _gpaOrMarksController = TextEditingController();
  final _institutionNameController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _addressController = TextEditingController();

  String? _educationType; // "school" or "college"
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    // Pre-fill if provided from basic registration
    if (widget.fullName != null) {
      _fullNameController.text = widget.fullName!;
    }
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
    if (widget.password != null) {
      _passwordController.text = widget.password!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _currentGradeController.dispose();
    _gpaOrMarksController.dispose();
    _institutionNameController.dispose();
    _courseNameController.dispose();
    _cgpaController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final localizations = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    
    if (_educationType == null) {
      setState(() {
        _errorMessage = 'Please select education type';
      });
      return;
    }

    // Validate required fields based on education type
    if (_educationType == 'school') {
      if (_currentGradeController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = localizations?.translate('please_fill_all_required_fields') ?? 'Please fill all required fields';
        });
        return;
      }
    } else if (_educationType == 'college') {
      if (_institutionNameController.text.trim().isEmpty || 
          _courseNameController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = localizations?.translate('please_fill_all_required_fields') ?? 'Please fill all required fields';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call registration API with student data
      final result = await LoginApi.register(
        name: widget.fullName ?? _fullNameController.text.trim(),
      email: widget.email ?? _emailController.text.trim(),
        phone: widget.mobileNumber,
      password: widget.password ?? _passwordController.text.trim(),
        type: 'student',
        educationType: _educationType!,
        // School fields
        currentGrade: _educationType == 'school' ? _currentGradeController.text.trim() : null,
        gpaOrMarks: _educationType == 'school' && _gpaOrMarksController.text.trim().isNotEmpty
            ? _gpaOrMarksController.text.trim()
            : null,
        // College fields
        institutionName: _educationType == 'college' && _institutionNameController.text.trim().isNotEmpty
            ? _institutionNameController.text.trim()
            : null,
        courseName: _educationType == 'college' && _courseNameController.text.trim().isNotEmpty
            ? _courseNameController.text.trim()
            : null,
        cgpa: _educationType == 'college' && _cgpaController.text.trim().isNotEmpty
            ? double.tryParse(_cgpaController.text.trim())
            : null,
        // Common field
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
    );

    setState(() {
      _isLoading = false;
    });

      if (result['status'] == true) {
        // Auto-login after successful registration
        final loginResult = await LoginApi.login(
          email: widget.email ?? _emailController.text.trim(),
          password: widget.password ?? _passwordController.text.trim(),
        );

        if (loginResult['status'] == true) {
          // Store the token
          final token = loginResult['token'] as String?;
          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', token);
          }
        }

        CustomSnackBar.showSuccess(
          context,
          result['message'] as String? ?? localizations?.translate('registration_successful') ?? 'Student registration successful!',
        );
        
        if (mounted) {
          // Show subscription plan modal after successful registration
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SubscriptionPlanScreen(
                isModal: true,
                onContinue: () {
                  Navigator.of(context).pop(); // Close modal
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MainNavigationScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          );
        }
    } else {
        setState(() {
          _errorMessage = result['message'] as String? ?? 'Student registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred during registration. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        //title: Text(localizations?.translate('student_registration') ?? 'Student Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations?.translate('create_student_account') ?? 'Create Student Account',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations?.translate('fill_details') ?? 'Fill in your details to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                // Show basic info card if provided, otherwise show form fields
                if (widget.fullName != null && widget.email != null && widget.password != null) ...[
                  // Display basic info (read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations?.translate('account_information') ?? 'Account Information',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.person, localizations?.fullName ?? 'Full Name', widget.fullName!),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.email, localizations?.email ?? 'Email', widget.email!),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.phone, localizations?.mobileNumber ?? 'Mobile Number', widget.mobileNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: '${localizations?.fullName ?? 'Full Name'} *',
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations?.translate('please_enter_full_name') ?? 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: '${localizations?.email ?? 'Email'} *',
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations?.translate('please_enter_email') ?? 'Please enter email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return localizations?.translate('please_enter_valid_email') ?? 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '${localizations?.password ?? 'Password'} *',
                      prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations?.translate('please_enter_password') ?? 'Please enter password';
                      }
                      if (value.length < 6) {
                        return localizations?.translate('password_min_length') ?? 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Mobile Number (read-only)
                  TextFormField(
                    initialValue: widget.mobileNumber,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: localizations?.mobileNumber ?? 'Mobile Number',
                      prefixIcon: const Icon(Icons.phone),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Education Type (School/College)
                DropdownButtonFormField<String>(
                  value: _educationType,
                  decoration: InputDecoration(
                    labelText: 'Education Type *',
                    prefixIcon: const Icon(Icons.school),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'school',
                      child: Text('School'),
                    ),
                    DropdownMenuItem(
                      value: 'college',
                      child: Text('College'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _educationType = value;
                      // Clear fields when switching types
                      if (value == 'school') {
                        _institutionNameController.clear();
                        _courseNameController.clear();
                        _cgpaController.clear();
                      } else {
                        _currentGradeController.clear();
                        _gpaOrMarksController.clear();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select education type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Conditional Fields based on Education Type
                if (_educationType == 'school') ...[
                  // Current Grade (for School)
                  TextFormField(
                    controller: _currentGradeController,
                  decoration: InputDecoration(
                    labelText: '${localizations?.currentGrade ?? 'Current Grade'} *',
                    prefixIcon: const Icon(Icons.school),
                    border: const OutlineInputBorder(),
                      hintText: 'e.g., Grade 9',
                    ),
                  validator: (value) {
                      if (_educationType == 'school' && (value == null || value.isEmpty)) {
                        return localizations?.translate('please_enter_current_grade') ?? 'Please enter current grade';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                  // GPA or Marks (for School)
                TextFormField(
                    controller: _gpaOrMarksController,
                  decoration: InputDecoration(
                      labelText: 'GPA / Marks',
                      prefixIcon: const Icon(Icons.star),
                    border: const OutlineInputBorder(),
                      hintText: 'e.g., 85%',
                  ),
                ),
                const SizedBox(height: 16),
                ] else if (_educationType == 'college') ...[
                  // Institution Name (for College)
                  TextFormField(
                    controller: _institutionNameController,
                  decoration: InputDecoration(
                      labelText: 'Institution Name *',
                      prefixIcon: const Icon(Icons.school_outlined),
                    border: const OutlineInputBorder(),
                      hintText: 'e.g., King Saud University',
                  ),
                    validator: (value) {
                      if (_educationType == 'college' && (value == null || value.isEmpty)) {
                        return 'Please enter institution name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Course Name (for College)
                  TextFormField(
                    controller: _courseNameController,
                    decoration: InputDecoration(
                      labelText: 'Course Name *',
                      prefixIcon: const Icon(Icons.book),
                      border: const OutlineInputBorder(),
                      hintText: 'e.g., Computer Science',
                    ),
                    validator: (value) {
                      if (_educationType == 'college' && (value == null || value.isEmpty)) {
                        return 'Please enter course name';
                      }
                      return null;
                  },
                ),
                const SizedBox(height: 16),
                  // CGPA (for College)
                TextFormField(
                    controller: _cgpaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                      labelText: 'CGPA',
                    prefixIcon: const Icon(Icons.star),
                    border: const OutlineInputBorder(),
                      hintText: 'e.g., 3.8',
                  ),
                ),
                const SizedBox(height: 16),
                ],
                // Address (Common for both)
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: localizations?.address ?? 'Address',
                    prefixIcon: const Icon(Icons.location_on),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorRed),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.errorRed),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                GradientButton(
                  text: localizations?.createAccount ?? 'Create Account',
                  icon: Icons.person_add,
                  isLoading: _isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

