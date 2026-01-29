import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mobile_number_field.dart';
import '../../l10n/app_localizations.dart';
import 'user_type_selection_screen.dart';

class BasicRegistrationScreen extends StatefulWidget {
  const BasicRegistrationScreen({super.key});

  @override
  State<BasicRegistrationScreen> createState() => _BasicRegistrationScreenState();
}

class _BasicRegistrationScreenState extends State<BasicRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final localizations = AppLocalizations.of(context);
    
    // Check if passwords match
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = localizations?.translate('passwords_do_not_match') ?? 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Don't call API here - just collect data and navigate to type selection
      // The actual registration will happen in parent/student registration screen
      
      setState(() {
        _isLoading = false;
      });

      // Navigate to user type selection screen with basic registration data
      if (mounted) {
        Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UserTypeSelectionScreen(
              mobileNumber: _mobileController.text.trim(),
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      ),
    );
      }
    } catch (e) {
    setState(() {
      _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/ektifi-logo copy.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  localizations?.translate('create_account') ?? 'Create Account',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations?.translate('fill_basic_details') ?? 'Fill in your basic details to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: localizations?.fullName ?? 'Full Name',
                    hintText: localizations?.fullName ?? 'Full Name',
                    prefixIcon: const Icon(
                      Icons.person,
                      color: AppTheme.accentCyan,
                    ),
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
                    labelText: localizations?.email ?? 'Email',
                    hintText: localizations?.email ?? 'Email',
                    prefixIcon: const Icon(
                      Icons.email,
                      color: AppTheme.accentCyan,
                    ),
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
                // Mobile Number
                MobileNumberField(
                  controller: _mobileController,
                ),
                const SizedBox(height: 16),
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: localizations?.password ?? 'Password',
                    hintText: localizations?.password ?? 'Password',
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: AppTheme.accentCyan,
                    ),
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
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: localizations?.translate('confirm_password') ?? 'Confirm Password',
                    hintText: localizations?.translate('confirm_password') ?? 'Confirm Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.accentCyan,
                    ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations?.translate('please_confirm_password') ?? 'Please confirm password';
                    }
                    if (value != _passwordController.text.trim()) {
                      return localizations?.translate('passwords_do_not_match') ?? 'Passwords do not match';
                    }
                    return null;
                  },
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
                  text: localizations?.translate('create_account') ?? 'Create Account',
                  icon: Icons.person_add,
                  isLoading: _isLoading,
                  onPressed: _register,
                ),
                const SizedBox(height: 24),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations?.translate('already_have_account') ?? 'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        localizations?.login ?? 'Login',
                        style: const TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
