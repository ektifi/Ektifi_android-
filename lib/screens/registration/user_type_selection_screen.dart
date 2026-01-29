import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../l10n/app_localizations.dart';
import 'parent_registration_screen.dart';
import 'student_registration_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final String mobileNumber;
  final String? fullName;
  final String? email;
  final String? password;

  const UserTypeSelectionScreen({
    super.key,
    required this.mobileNumber,
    this.fullName,
    this.email,
    this.password,
  });

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  UserType? _selectedType;

  void _continue() {
    final localizations = AppLocalizations.of(context);
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations?.translate('please_select_user_type') ?? 'Please select a user type'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    if (_selectedType == UserType.parent) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ParentRegistrationScreen(
            mobileNumber: widget.mobileNumber,
            fullName: widget.fullName,
            email: widget.email,
            password: widget.password,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentRegistrationScreen(
            mobileNumber: widget.mobileNumber,
            fullName: widget.fullName,
            email: widget.email,
            password: widget.password,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        //title: Text(localizations?.selectUserType ?? 'Select User Type'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                localizations?.iAmA ?? 'I am a...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                localizations?.chooseAccountType ?? 'Choose your account type',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Parent Option
              _buildUserTypeCard(
                title: localizations?.parent ?? 'Parent',
                icon: Icons.family_restroom,
                description: localizations?.parentDescription ?? 'Manage multiple children\'s profiles and applications',
                isSelected: _selectedType == UserType.parent,
                onTap: () {
                  setState(() {
                    _selectedType = UserType.parent;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Student Option
              _buildUserTypeCard(
                title: localizations?.student ?? 'Student',
                icon: Icons.person,
                description: localizations?.studentDescription ?? 'Manage your own academic details and admission forms',
                isSelected: _selectedType == UserType.student,
                onTap: () {
                  setState(() {
                    _selectedType = UserType.student;
                  });
                },
              ),
              const Spacer(),
              GradientButton(
                text: localizations?.continueText ?? 'Continue',
                icon: Icons.arrow_forward,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryIndigo
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppTheme.primaryIndigo.withOpacity(0.1)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryIndigo
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryIndigo
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryIndigo,
              ),
          ],
        ),
      ),
    );
  }
}

