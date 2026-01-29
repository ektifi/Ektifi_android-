import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_snackbar.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/parent_model.dart';
import '../../api/login_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_navigation_screen.dart';

class ParentRegistrationScreen extends StatefulWidget {
  final String mobileNumber;
  final String? fullName;
  final String? email;
  final String? password;

  const ParentRegistrationScreen({
    super.key,
    required this.mobileNumber,
    this.fullName,
    this.email,
    this.password,
  });

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  RelationshipType _relationshipType = RelationshipType.guardian;
  int? _numberOfChildren;
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
    _addressController.dispose();
    super.dispose();
  }

  String _translateRelationshipType(RelationshipType type, AppLocalizations? loc) {
    if (loc == null) {
      return type.name[0].toUpperCase() + type.name.substring(1);
    }
    switch (type) {
      case RelationshipType.father:
        return loc.father;
      case RelationshipType.mother:
        return loc.mother;
      case RelationshipType.guardian:
        return loc.guardian;
    }
  }

  Future<void> _register() async {
    final localizations = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_numberOfChildren == null) {
      setState(() {
        _errorMessage = localizations?.translate('please_fill_all_required_fields') ?? 'Please fill all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Convert relationship type to string format
      String relationshipTypeStr;
      switch (_relationshipType) {
        case RelationshipType.father:
          relationshipTypeStr = 'Father';
          break;
        case RelationshipType.mother:
          relationshipTypeStr = 'Mother';
          break;
        case RelationshipType.guardian:
          relationshipTypeStr = 'Guardian';
          break;
      }

      // Call registration API with all parent data
      final result = await LoginApi.register(
        name: widget.fullName ?? _fullNameController.text.trim(),
      email: widget.email ?? _emailController.text.trim(),
      password: widget.password ?? _passwordController.text.trim(),
        type: 'parent',
        relationshipType: relationshipTypeStr,
        noOfChildren: _numberOfChildren!,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
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
          result['message'] as String? ?? localizations?.translate('registration_successful') ?? 'Parent registration successful!',
        );
        
        if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
        (route) => false,
      );
        }
    } else {
        setState(() {
          _errorMessage = result['message'] as String? ?? 'Parent registration failed. Please try again.';
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
        //title: Text(localizations?.translate('parent_registration') ?? 'Parent Registration'),
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
                  localizations?.translate('create_parent_account') ?? 'Create Parent Account',
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
                const SizedBox(height: 20),
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
                // Relationship Type
                Builder(
                  builder: (context) {
                    return DropdownButtonFormField<RelationshipType>(
                      value: _relationshipType,
                      decoration: InputDecoration(
                        labelText: '${localizations?.relationshipType ?? 'Relationship Type'} *',
                        prefixIcon: Icon(Icons.family_restroom, color: AppTheme.accentCyan),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.accentCyan, width: 2),
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      icon: Icon(Icons.arrow_drop_down, color: AppTheme.accentCyan),
                      isExpanded: false,
                      itemHeight: 56,
                      menuMaxHeight: 200,
                      alignment: AlignmentDirectional.centerStart,
                      items: RelationshipType.values.map((type) {
                        final isSelected = type == _relationshipType;
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            _translateRelationshipType(type, localizations),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _relationshipType = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return localizations?.translate('please_select_relationship_type') ?? 'Please select relationship type';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Number of Children
                TextFormField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '${localizations?.numberOfChildren ?? 'Number of Children'} *',
                    prefixIcon: const Icon(Icons.child_care),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _numberOfChildren = value.isEmpty ? null : int.tryParse(value);
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations?.translate('please_enter_number_of_children') ?? 'Please enter number of children';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num < 1) {
                      return localizations?.translate('please_enter_valid_number') ?? 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Preferred Language
                // DropdownButtonFormField<String>(
                //   value: _preferredLanguage,
                //   decoration: InputDecoration(
                //     labelText: localizations?.preferredLanguage ?? 'Preferred Language',
                //     prefixIcon: const Icon(Icons.language),
                //     border: const OutlineInputBorder(),
                //   ),
                //   items: [
                //     DropdownMenuItem(
                //       value: 'English',
                //       child: Text(localizations?.english ?? 'English'),
                //     ),
                //     DropdownMenuItem(
                //       value: 'Arabic',
                //       child: Text(localizations?.arabic ?? 'Arabic'),
                //     ),
                //   ],
                //   onChanged: (value) {
                //     setState(() {
                //       _preferredLanguage = value;
                //     });
                //   },
                // ),
                // const SizedBox(height: 16),
                // Address
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

