import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/mobile_number_field.dart';
import '../../l10n/app_localizations.dart';
import '../registration/basic_registration_screen.dart';
import '../registration/user_type_selection_screen.dart';
import '../main_navigation_screen.dart';
import 'email_login_screen.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({super.key});

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 20;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }


  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.sendOTP(_mobileController.text.trim());

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _otpSent = true;
        _startResendTimer();
        CustomSnackBar.showSuccess(context, result['message'] as String);
      } else {
        _errorMessage = result['message'] as String;
      }
    });
  }

  Future<void> _verifyOTP() async {
    final localizations = AppLocalizations.of(context);
    if (_otpController.text.trim().isEmpty || _otpController.text.trim().length != 4) {
      setState(() {
        _errorMessage = localizations?.translate('enter_otp') ?? 'Please enter OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.verifyOTP(
      _mobileController.text.trim(),
      _otpController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      if (result['isNewUser'] == true) {
        // New user - go to user type selection
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UserTypeSelectionScreen(
              mobileNumber: _mobileController.text.trim(),
            ),
          ),
        );
      } else {
        // Existing user - go to main navigation screen
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
                if (!_otpSent) ...[
                  MobileNumberField(
                    controller: _mobileController,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: localizations?.otp ?? 'OTP',
                      hintText: '____',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        color: Colors.grey[400],
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Resend OTP Button with Timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _resendTimer > 0 ? null : () {
                          _sendOTP();
                        },
                        child: Text(
                          _resendTimer > 0
                              ? '${localizations?.resendOTP ?? 'Resend OTP'} (${_resendTimer}s)'
                              : (localizations?.resendOTP ?? 'Resend OTP'),
                          style: TextStyle(
                            color: _resendTimer > 0
                                ? Colors.grey
                                : AppTheme.accentCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                  text: _otpSent 
                      ? (localizations?.verifyOTP ?? 'Verify OTP')
                      : (localizations?.sendOTP ?? 'Send OTP'),
                  icon: _otpSent ? Icons.verified : Icons.send,
                  isLoading: _isLoading,
                  onPressed: _otpSent ? _verifyOTP : _sendOTP,
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _otpSent = false;
                        _otpController.clear();
                        _errorMessage = null;
                        _resendTimer = 0;
                        _timer?.cancel();
                      });
                    },
                    child: Text(localizations?.changeMobileNumber ?? 'Change Mobile Number'),
                  ),
                ] else ...[
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
                  // Email Login Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const EmailLoginScreen(),
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
                        const Icon(Icons.email, color: AppTheme.accentCyan),
                        const SizedBox(width: 8),
                        Text(
                          localizations?.loginWithEmail ?? 'Login with Email',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

