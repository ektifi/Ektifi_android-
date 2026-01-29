import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../api/login_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_snackbar.dart';
import '../../l10n/app_localizations.dart';
import '../main_navigation_screen.dart';
import 'otp_login_screen.dart';
import '../registration/basic_registration_screen.dart';
import '../registration/user_type_selection_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  final bool returnToPrevious;
  
  const EmailLoginScreen({super.key, this.returnToPrevious = false});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final localizations = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // Show success message
      CustomSnackBar.showSuccess(
        context,
        result['message'] as String? ?? localizations?.translate('login_successful') ?? 'Login successful',
      );
      
      // Get the token to check user type
      final token = result['token'] as String?;
      
      if (token != null) {
        // Check user type from API
        setState(() {
          _isLoading = true; // Show loading while checking user type
        });
        
        final userTypeResult = await LoginApi.checkUserType(token: token);
        
        setState(() {
          _isLoading = false;
        });
        
        if (userTypeResult['status'] == true) {
          final isParent = userTypeResult['is_parent'] as bool? ?? false;
          final isStudent = userTypeResult['is_student'] as bool? ?? false;
          
          // If both are false, user needs to complete registration
          if (!isParent && !isStudent) {
            // Navigate to user type selection screen
            if (widget.returnToPrevious) {
              // If opened from another screen, pop first then navigate
              Navigator.of(context).pop(); // Pop login screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserTypeSelectionScreen(
                    mobileNumber: '', // Will be filled during registration
                    email: _emailController.text.trim(),
                  ),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => UserTypeSelectionScreen(
                    mobileNumber: '', // Will be filled during registration
                    email: _emailController.text.trim(),
                  ),
                ),
              );
            }
            return;
          }
          // If user is already registered (isParent or isStudent is true), proceed normally
        }
      }
      
      // If opened from another screen (like institution details), return to previous screen
      if (widget.returnToPrevious) {
        Navigator.of(context).pop(true); // Return true to indicate successful login
      } else {
        // Navigate to main navigation screen (default behavior)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
        (route) => false,
      );
      }
    } else {
      setState(() {
        _errorMessage = result['message'] as String;
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
                  text: localizations?.login ?? 'Login',
                  icon: Icons.login,
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                    CustomSnackBar.showError(
                      context,
                      localizations?.translate('forgot_password_coming_soon') ?? 'Forgot password feature coming soon',
                    );
                  },
                  child: Text(localizations?.forgotPassword ?? 'Forgot Password?'),
                ),
                const SizedBox(height: 24),
                // Divider with "OR"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        localizations?.or ?? 'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // OTP Login Button
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const OTPLoginScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.accentCyan, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_android, color: AppTheme.accentCyan),
                      const SizedBox(width: 8),
                      Text(
                        localizations?.loginWithMobileOTP ?? 'Login with Mobile (OTP)',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Registration Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations?.translate('dont_have_account') ?? 'Don\'t have an account? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BasicRegistrationScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        localizations?.translate('register') ?? 'Register',
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

