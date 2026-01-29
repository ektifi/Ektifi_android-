import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

// Country code to mobile number length mapping
final Map<String, int> _countryMobileLengths = {
  '+966': 9, // Saudi Arabia
  '+91': 10, // India
  '+1': 10, // USA/Canada
  '+44': 10, // UK
  '+971': 9, // UAE
  '+974': 8, // Qatar
  '+965': 8, // Kuwait
  '+973': 8, // Bahrain
  '+968': 8, // Oman
  '+20': 10, // Egypt
  '+92': 10, // Pakistan
  '+880': 10, // Bangladesh
  '+62': 10, // Indonesia
  '+60': 10, // Malaysia
  '+66': 9, // Thailand
  '+84': 10, // Vietnam
  '+63': 10, // Philippines
  '+65': 8, // Singapore
  '+86': 11, // China
  '+81': 10, // Japan
  '+82': 10, // South Korea
  '+61': 9, // Australia
  '+27': 9, // South Africa
  '+49': 11, // Germany
  '+33': 9, // France
  '+39': 10, // Italy
  '+34': 9, // Spain
  '+31': 9, // Netherlands
  '+46': 9, // Sweden
  '+47': 8, // Norway
  '+45': 8, // Denmark
  '+358': 9, // Finland
  '+32': 9, // Belgium
  '+41': 9, // Switzerland
  '+43': 10, // Austria
  '+351': 9, // Portugal
  '+30': 10, // Greece
  '+353': 9, // Ireland
  '+48': 9, // Poland
  '+420': 9, // Czech Republic
  '+36': 9, // Hungary
  '+40': 10, // Romania
  '+7': 10, // Russia/Kazakhstan
  '+90': 10, // Turkey
  '+52': 10, // Mexico
  '+55': 11, // Brazil
  '+54': 10, // Argentina
  '+56': 9, // Chile
  '+57': 10, // Colombia
  '+51': 9, // Peru
};

int _getMobileLengthForCountry(String? dialCode) {
  if (dialCode == null) return 10; // Default
  return _countryMobileLengths[dialCode] ?? 10; // Default to 10 if not found
}

class MobileNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? labelText;
  final String? hintText;
  final bool readOnly;
  final String? initialCountryCode;

  const MobileNumberField({
    super.key,
    required this.controller,
    this.validator,
    this.labelText,
    this.hintText,
    this.readOnly = false,
    this.initialCountryCode,
  });

  @override
  State<MobileNumberField> createState() => _MobileNumberFieldState();
}

class _MobileNumberFieldState extends State<MobileNumberField> {
  CountryCode? _selectedCountryCode;

  @override
  void initState() {
    super.initState();
    // Initialize with Saudi Arabia (+966) by default
    _selectedCountryCode = CountryCode.fromDialCode(widget.initialCountryCode ?? '+966');
  }

  @override
  void didUpdateWidget(MobileNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't reset country code if user has already selected one
    // Only update if widget is being recreated with a different initialCountryCode
    // and we haven't manually changed it
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Row(
      children: [
        // Country Code Picker
        Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CountryCodePicker(
            onChanged: (CountryCode code) {
              if (code.dialCode != _selectedCountryCode?.dialCode) {
                setState(() {
                  _selectedCountryCode = code;
                });
                // Trigger validation when country code changes
                if (widget.controller.text.isNotEmpty) {
                  // Use a delay to ensure state is updated and form field rebuilds
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) {
                      try {
                        // Find the form and validate
                        Form.of(context).validate();
                      } catch (e) {
                        // Form not found, ignore
                      }
                    }
                  });
                }
              }
            },
            initialSelection: _selectedCountryCode?.code ?? 'SA',
            favorite: const ['+966', 'SA'],
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            showFlag: true,
            showFlagDialog: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            dialogTextStyle: const TextStyle(
              fontSize: 16,
            ),
            searchDecoration: InputDecoration(
              hintText: localizations?.translate('search_country') ?? 'Search country',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search),
            ),
            dialogSize: Size(
              MediaQuery.of(context).size.width * 0.9,
              MediaQuery.of(context).size.height * 0.7,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Mobile Number Input
        Expanded(
          child: Builder(
            builder: (context) {
              return TextFormField(
                key: ValueKey('${_selectedCountryCode?.dialCode}_${widget.controller.hashCode}'),
                controller: widget.controller,
                keyboardType: TextInputType.phone,
                readOnly: widget.readOnly,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: widget.labelText ?? localizations?.mobileNumber ?? 'Mobile Number',
                  hintText: widget.hintText ?? localizations?.mobileNumber ?? 'Mobile Number',
                  prefixIcon: const Icon(
                    Icons.phone_android,
                    color: AppTheme.accentCyan,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: widget.validator ??
                    (value) {
                      if (value == null || value.isEmpty) {
                        return localizations?.translate('please_enter_mobile_number') ??
                            'Please enter mobile number';
                      }
                      final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                      // Always get the current country code from state at validation time
                      // This ensures we use the latest selected country code
                      final currentCountryCode = _selectedCountryCode?.dialCode ?? '+966';
                      final expectedLength = _getMobileLengthForCountry(currentCountryCode);
                      
                      if (digitsOnly.length != expectedLength) {
                        // Use dynamic translation for mobile number length
                        final errorKey = 'mobile_number_must_be_digits';
                        final errorMessage = localizations?.translate(errorKey);
                        if (errorMessage != null && errorMessage != errorKey) {
                          return errorMessage.replaceAll('{digits}', expectedLength.toString());
                        }
                        return 'Mobile number must be $expectedLength digits';
                      }
                      return null;
                    },
              );
            },
          ),
        ),
      ],
    );
  }
}

