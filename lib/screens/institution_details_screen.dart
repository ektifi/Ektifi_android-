import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../api/api_service.dart';
import '../services/auth_service.dart';
import 'application_form_screen.dart';
import 'auth/email_login_screen.dart';
import 'chat_detail_screen.dart';

class InstitutionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? institution;
  final int? institutionId;
  final bool hideApplyButton;

  const InstitutionDetailsScreen({
    super.key,
    this.institution,
    this.institutionId,
    this.hideApplyButton = false,
  });

  @override
  State<InstitutionDetailsScreen> createState() => _InstitutionDetailsScreenState();
}

class _InstitutionDetailsScreenState extends State<InstitutionDetailsScreen> {
  Map<String, dynamic>? _institutionData;
  List<dynamic>? _programCourses;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isInWishlist = false;
  int? _applicationId; // Application ID if user has applied
  bool _hasApplied = false; // Whether user has applied to this institution
  int _selectedProgramLevelIndex = 0; // For tabs
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadInstitutionDetails();
    _checkWishlistStatus();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _hasApplied = false;
          _applicationId = null;
        });
        return;
      }

      // Determine institution ID
      int? id = widget.institutionId;
      if (id == null && widget.institution != null) {
        final instId = widget.institution!['id'];
        if (instId != null) {
          id = instId is int ? instId : int.tryParse(instId.toString());
        }
      }
      
      if (id == null && _institutionData != null) {
        final instId = _institutionData!['id'];
        if (instId != null) {
          id = instId is int ? instId : int.tryParse(instId.toString());
        }
      }

      if (id == null) {
        setState(() {
          _hasApplied = false;
          _applicationId = null;
        });
        return;
      }

      final appId = await ApiService.getApplicationIdForInstitution(
        institutionId: id,
        token: token,
      );

      setState(() {
        _hasApplied = appId != null;
        _applicationId = appId;
      });
    } catch (e) {
      print('Error checking application status: $e');
      setState(() {
        _hasApplied = false;
        _applicationId = null;
      });
    }
  }

  Future<void> _handleInquire() async {
    // Check if user is logged in
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (!isLoggedIn) {
      // User is not logged in, navigate to login screen
      final loginResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const EmailLoginScreen(
            returnToPrevious: true,
          ),
        ),
      );

      // If login was successful, retry the inquire action
      if (loginResult == true) {
        _handleInquire();
      }
      return;
    }

    // Get authentication token
    final token = await _authService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to send inquiries'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Determine institution ID
    int? institutionId = widget.institutionId;
    if (institutionId == null && widget.institution != null) {
      final instId = widget.institution!['id'];
      if (instId != null) {
        institutionId = instId is int ? instId : int.tryParse(instId.toString());
      }
    }
    
    if (institutionId == null && _institutionData != null) {
      final instId = _institutionData!['id'];
      if (instId != null) {
        institutionId = instId is int ? instId : int.tryParse(instId.toString());
      }
    }

    if (institutionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify institution'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create or get conversation
      final conversationData = await ApiService.createOrGetConversation(
        institutionId: institutionId,
        token: token,
      );

      // Get Firebase conversation ID (for Firestore operations)
      final firebaseConversationId = conversationData['firebase_conversation_id'] as String?;
      
      // Get Laravel database conversation ID (for API calls)
      final laravelConversationId = conversationData['conversation_id'] as String? ?? 
                                    conversationData['id'] as String?;
      
      // Use Firebase ID for Firestore, fallback to Laravel ID if Firebase ID not available
      final conversationId = firebaseConversationId ?? laravelConversationId;

      if (conversationId == null) {
        throw Exception('Conversation ID not found in response');
      }

      // Get institution name
      final institutionName = _institutionData?['institution_name'] as String? ?? 
                            _institutionData?['name'] as String? ??
                            widget.institution?['institution_name'] as String? ??
                            widget.institution?['name'] as String? ??
                            'Institution';

      // Get institution logo/avatar
      final about = _institutionData?['about'] as Map<String, dynamic>?;
      final institutionAvatar = about?['logo'] as String?;

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to chat screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: conversationId, // Firebase ID for Firestore
              laravelConversationId: laravelConversationId, // Laravel DB ID for API calls
              institutionName: institutionName,
              institutionAvatar: institutionAvatar,
              institutionId: institutionId,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('Error creating conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _checkWishlistStatus() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _isInWishlist = false;
        });
        return;
      }

      // Determine institution ID
      int? id = widget.institutionId;
      if (id == null && widget.institution != null) {
        final instId = widget.institution!['id'];
        if (instId != null) {
          id = instId is int ? instId : int.tryParse(instId.toString());
        }
      }
      
      if (id == null && _institutionData != null) {
        final instId = _institutionData!['id'];
        if (instId != null) {
          id = instId is int ? instId : int.tryParse(instId.toString());
        }
      }

      if (id == null) {
        setState(() {
          _isInWishlist = false;
        });
        return;
      }

      final isInWishlist = await ApiService.checkWishlistStatus(
        institutionId: id,
        token: token,
      );

      setState(() {
        _isInWishlist = isInWishlist;
      });
    } catch (e) {
      print('Error checking wishlist status: $e');
      setState(() {
        _isInWishlist = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.translate('please_login') ?? 'Please login to add to wishlist',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Determine institution ID
      int? id = widget.institutionId;
      if (id == null && widget.institution != null) {
        final instId = widget.institution!['id'];
        if (instId != null) {
          id = instId is int ? instId : int.tryParse(instId.toString());
        }
      }
      
      if (id == null && _institutionData != null) {
        final instId = _institutionData!['id'];
        if (instId != null) {
          id = instId is int ? instId : int.tryParse(instId.toString());
        }
      }

      if (id == null) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.translate('error') ?? 'Error: Institution ID not found',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final localizations = AppLocalizations.of(context);
      
      if (_isInWishlist) {
        // Remove from wishlist
        await ApiService.removeFromWishlist(
          institutionId: id,
          token: token,
        );
        setState(() {
          _isInWishlist = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations?.translate('wishlist') ?? 'Wishlist'}: Removed',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.grey[600],
          ),
        );
      } else {
        // Add to wishlist
        await ApiService.addToWishlist(
          institutionId: id,
          token: token,
        );
        setState(() {
          _isInWishlist = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations?.translate('wishlist') ?? 'Wishlist'}: Added',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.accentCyan,
          ),
        );
      }
    } catch (e) {
      print('Error toggling wishlist: $e');
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.translate('error') ?? 'Error: ${e.toString()}',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadInstitutionDetails() async {
    // Determine institution ID
    int? id = widget.institutionId;
    if (id == null && widget.institution != null) {
      // Try to get ID from institution data
      final instId = widget.institution!['id'];
      if (instId != null) {
        id = instId is int ? instId : int.tryParse(instId.toString());
      }
    }

    // If we have an ID, always fetch from API to get latest data including program_courses
    if (id != null) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final response = await ApiService.fetchInstitutionDetails(id);
        
        setState(() {
          // New API format: data object contains all institution info
          _institutionData = response['data'] as Map<String, dynamic>?;
          // program_levels is now inside data
          _programCourses = _institutionData?['program_levels'] as List<dynamic>?;
          _isLoading = false;
        });
        // Check wishlist and application status after loading institution details
        _checkWishlistStatus();
        _checkApplicationStatus();
        return;
      } catch (e) {
        // If API fails, fall back to provided data if available
        print('Error fetching from API: $e');
        if (widget.institution != null) {
          setState(() {
            _institutionData = widget.institution;
            _programCourses = widget.institution?['program_courses'] as List<dynamic>?;
            _isLoading = false;
          });
          return;
        }
        setState(() {
          _errorMessage = 'Failed to load institution details: ${e.toString()}';
          _isLoading = false;
        });
        return;
      }
    }

    // If no ID but institution data is provided, use it directly
    if (widget.institution != null) {
      setState(() {
        _institutionData = widget.institution;
        _programCourses = widget.institution?['program_courses'] as List<dynamic>?;
        _isLoading = false;
      });
      return;
    }

    // No data available
    setState(() {
      _errorMessage = 'Institution ID or data is required';
      _isLoading = false;
    });
  }

  String _getFirstLetter(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  String _getNameKey(String name) {
    final nameMap = {
      'Al-Faisal International School': 'al_faisal_international_school',
      'Riyadh Schools': 'riyadh_schools',
      'British International School': 'british_international_school',
      'Al-Noor Girls School': 'al_noor_girls_school',
      'Indian International School': 'indian_international_school',
      'King Fahd School': 'king_fahd_school',
      'IB World School': 'ib_world_school',
      'Al-Ahsa Girls Academy': 'al_ahsa_girls_academy',
      'Philippine School of Riyadh': 'philippine_school_riyadh',
      'Pakistani International School': 'pakistani_international_school',
      'French International School': 'french_international_school',
      'Canadian International School': 'canadian_international_school',
      'Al-Madinah Boys School': 'al_madinah_boys_school',
      'Mecca Girls School': 'mecca_girls_school',
      'Charter School of Excellence': 'charter_school_excellence',
      'Al-Abha International School': 'al_abha_international_school',
      'Tabuk Boys Academy': 'tabuk_boys_academy',
      'Jubail Girls School': 'jubail_girls_school',
      'Yanbu International Academy': 'yanbu_international_academy',
      'Al-Khobar Private School': 'al_khobar_private_school',
      'King Saud University': 'king_saud_university',
      'King Fahd University of Petroleum & Minerals': 'king_fahd_university_petroleum',
      'Princess Nourah bint Abdulrahman University': 'princess_nourah_university',
      'King Abdulaziz University': 'king_abdulaziz_university',
      'Imam Muhammad ibn Saud Islamic University': 'imam_muhammad_university',
      'King Faisal University': 'king_faisal_university',
      'Umm Al-Qura University': 'umm_al_qura_university',
      'Taif University': 'taif_university',
      'King Khalid University': 'king_khalid_university',
      'Alfaisal University': 'alfaisal_university',
      'Prince Sultan University': 'prince_sultan_university',
      'Effat University': 'effat_university',
      'Dar Al-Hekma University': 'dar_al_hekma_university',
      'King Saud bin Abdulaziz University for Health Sciences': 'king_saud_health_sciences',
      'King Saud Medical City College': 'king_saud_medical_city',
      'Riyadh Community College': 'riyadh_community_college',
      'Jeddah Technical College': 'jeddah_technical_college',
      'Dammam Technical College': 'dammam_technical_college',
      'Qassim University': 'qassim_university',
      'Hail University': 'hail_university',
    };
    return nameMap[name] ?? name.toLowerCase().replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _institutionData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryIndigo),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Failed to load institution details',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInstitutionDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final institution = _institutionData!;
    // New API format: institution_name instead of name
    final institutionName = institution['institution_name'] as String? ?? 
                           institution['name'] as String? ?? 
                           'Unknown';
    final about = institution['about'] as Map<String, dynamic>?;
    final logo = about?['logo'] as String?;
    final description = about?['description'] as String?;
    final institutionType = about?['institution_type'] as String?;
    final institutionTypeDetail = about?['institution_type_detail'] as String?;
    final genderType = about?['gender_type'] as String?;
    final programsOrLevels = about?['programs_or_levels'] as String?;
    final applicationFee = about?['application_fee'] as String?;
    final contact = about?['contact'] as Map<String, dynamic>?;
    final phone = contact?['official_phone'] as String? ?? contact?['phone'] as String?;
    final email = contact?['official_email'] as String? ?? contact?['email'] as String?;
    final city = contact?['city'] as String?;
    final governingAuthority = institution['governing_authority'] as String?;
    final programLevels = institution['program_levels'] as List<dynamic>?;
    
    // Check if it's a college (for showing first letter when logo is null)
    final isCollege = institutionType == 'college';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: _isInWishlist ? Colors.red : Colors.white,
            ),
            onPressed: _toggleWishlist,
            tooltip: localizations?.translate('wishlist') ?? 'Wishlist',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Large Header Image
              SliverToBoxAdapter(
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: logo != null && logo.isNotEmpty
                        ? DecorationImage(
                            image: AssetImage(logo),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) => null,
                          )
                        : null,
                  ),
                  child: logo == null || logo.isEmpty
                      ? (isCollege 
                          ? _buildHeaderAvatar(institutionName)
                          : Container())
                      : null,
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Institution Name and Affiliation Card
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations?.translate(_getNameKey(institutionName)) ?? institutionName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                            if (governingAuthority != null && governingAuthority.isNotEmpty) ...[
                              const SizedBox(height: 4),
                                    Text(
                                'Affiliated to ${governingAuthority.toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                              ],
                            ),
                          ),
                      // Programs Offered Section
                      if (programLevels != null && programLevels.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Programs Offered',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Program Level Tabs
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: programLevels.length,
                            itemBuilder: (context, index) {
                              final programLevel = programLevels[index];
                              final programLevelData = programLevel['program_level'] as Map<String, dynamic>?;
                              final programName = programLevelData?['program_name'] as String? ?? '';
                              final isSelected = index == _selectedProgramLevelIndex;
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    programName.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedProgramLevelIndex = index;
                                    });
                                  },
                                  selectedColor: AppTheme.primaryIndigo,
                                  backgroundColor: Colors.grey[200],
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Courses for Selected Program Level
                        _buildProgramLevelCourses(
                          programLevels[_selectedProgramLevelIndex],
                          applicationFee,
                        localizations,
                      ),
                        const SizedBox(height: 24),
                      ],
                      // About the Institution Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About the Institution',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 12),
                            if (description != null && description.isNotEmpty)
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              )
                            else
                              Text(
                                'No description available.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Show full description
                                },
                                child: Text(
                                  'Read More >',
                                  style: TextStyle(
                                    color: AppTheme.primaryIndigo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Contact Information
                      if ((phone != null && phone.isNotEmpty) || (email != null && email.isNotEmpty)) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildSectionTitle(
                          localizations?.translate('contact_information') ?? 'Contact Information',
                          localizations,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildContactCard(
                          phone: phone,
                          email: email,
                          localizations: localizations,
                        ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const SizedBox(height: 80), // Bottom padding for buttons
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating action buttons
          Positioned(
            left: 16,
            right: 16,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Enquiry Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleInquire(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.accentCyan),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.question_mark, size: 20, color: AppTheme.accentCyan),
                          const SizedBox(width: 8),
                          Text(
                            localizations?.translate('Enquiry') ?? 'Enquiry',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Apply/Update Button
                  if (!widget.hideApplyButton) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Check if user is logged in
                          final isLoggedIn = await _authService.isLoggedIn();
                          
                          if (!isLoggedIn) {
                            // User is not logged in, navigate to login screen
                            final loginResult = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const EmailLoginScreen(
                                  returnToPrevious: true,
                                ),
                              ),
                            );
                            
                            // If login was successful, recheck application status and proceed
                            if (loginResult == true && mounted) {
                              await _checkApplicationStatus();
                              // Determine if it's a school based on institution type
                              final isSchool = institutionType == 'school';
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ApplicationFormScreen(
                                    institution: institution,
                                    isSchool: isSchool,
                                    applicationId: _applicationId, // Pass application ID if exists
                                  ),
                                ),
                              );
                            }
                          } else {
                            // User is logged in
                            // Determine if it's a school based on institution type
                            final isSchool = institutionType == 'school';
                            
                            // If user has applied, pass application ID for editing
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ApplicationFormScreen(
                                  institution: institution,
                                  isSchool: isSchool,
                                  applicationId: _applicationId, // Pass application ID if exists
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryIndigo,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasApplied ? Icons.edit : Icons.send,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hasApplied
                                  ? (localizations?.translate('update_now') ?? 'Update Now')
                                  : (localizations?.translate('apply_now') ?? 'Apply Now'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final firstLetter = _getFirstLetter(name);
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppTheme.primaryIndigo,
      child: Text(
        firstLetter,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar(String name) {
    final firstLetter = _getFirstLetter(name);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.primaryIndigo,
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProgramLevelCourses(
    Map<String, dynamic> programLevel,
    String? defaultApplicationFee,
    AppLocalizations? localizations,
  ) {
    final courses = programLevel['courses'] as List<dynamic>? ?? [];
    
    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No courses available for this program level.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: courses.map<Widget>((courseData) {
          final course = courseData as Map<String, dynamic>;
          final courseName = course['course_name'] as String? ?? '';
          final subCourses = course['sub_courses'] as List<dynamic>? ?? [];
          
          return _buildExpandableCourseSection(
            courseName: courseName,
            subCourses: subCourses,
            applicationFee: defaultApplicationFee,
            localizations: localizations,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandableCourseSection({
    required String courseName,
    required List<dynamic> subCourses,
    String? applicationFee,
    AppLocalizations? localizations,
  }) {
    return ExpansionTile(
      leading: const Icon(Icons.school, color: AppTheme.primaryIndigo),
      title: Text(
        courseName.toUpperCase(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      children: subCourses.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No sub-courses available.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ]
          : subCourses.map<Widget>((subCourseData) {
              final subCourse = subCourseData as Map<String, dynamic>;
              final subCourseName = subCourse['sub_course_name'] as String? ?? '';
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  subCourseName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: applicationFee != null
                    ? Text(
                        'Application Fee: $applicationFee SAR',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
              );
            }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, AppLocalizations? localizations) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescriptionCard(String description, AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildKeyInformationCard({
    String? institutionType,
    String? genderType,
    String? programsOrLevels,
    String? applicationFee,
    AppLocalizations? localizations,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (institutionType != null && institutionType.isNotEmpty)
            _buildInfoRow(
              localizations?.translate('institution_type') ?? 'Institution Type',
              institutionType,
              Icons.business,
              localizations,
            ),
          if (institutionType != null && genderType != null) const SizedBox(height: 12),
          if (genderType != null && genderType.isNotEmpty)
            _buildInfoRow(
              localizations?.translate('gender_type') ?? 'Gender Type',
              genderType,
              Icons.people,
              localizations,
            ),
          if (genderType != null && programsOrLevels != null) const SizedBox(height: 12),
          if (programsOrLevels != null && programsOrLevels.isNotEmpty)
            _buildInfoRow(
              localizations?.translate('programs_or_levels') ?? 'Programs/Levels',
              programsOrLevels,
              Icons.school,
              localizations,
            ),
          if (programsOrLevels != null && applicationFee != null) const SizedBox(height: 12),
          if (applicationFee != null && applicationFee.isNotEmpty)
            _buildInfoRow(
              localizations?.translate('application_fee') ?? 'Application Fee',
              '$applicationFee SAR',
              Icons.attach_money,
              localizations,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, AppLocalizations? localizations) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.accentCyan),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgramCoursesCard(List<dynamic> programCourses, AppLocalizations? localizations) {
    return Column(
      children: programCourses.map<Widget>((course) {
        final courseMap = course as Map<String, dynamic>;
        final programName = courseMap['program_name'] as String? ?? '';
        final seatsAvailable = courseMap['seats_available'] as int? ?? 0;
        final seatsTotal = courseMap['seats_total'] as int? ?? 0;
        final eligibilityCriteria = courseMap['eligibility_criteria'] as String?;
        final fees = courseMap['fees'] as String?;
        final gradeLevel = courseMap['grade_level'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Program Name and Seats in one row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      programName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$seatsAvailable/$seatsTotal ${localizations?.translate('seats') ?? 'seats'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
              // Eligibility Criteria as description
              if (eligibilityCriteria != null && eligibilityCriteria.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  eligibilityCriteria,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
              // Additional info (Grade Level and Fees)
              if (gradeLevel != null || fees != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (gradeLevel != null && gradeLevel.isNotEmpty)
                      _buildCourseInfoChip(
                        localizations?.translate('grade_level') ?? 'Grade Level',
                        gradeLevel,
                        localizations,
                      ),
                    if (fees != null && fees.isNotEmpty)
                      _buildCourseInfoChip(
                        localizations?.translate('fees') ?? 'Fees',
                        '$fees SAR',
                        localizations,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseInfoChip(String label, String value, AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    String? phone,
    String? email,
    AppLocalizations? localizations,
  }) {
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasEmail = email != null && email.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (hasPhone)
            _buildContactRow(
              Icons.phone,
              localizations?.translate('phone') ?? 'Phone',
              phone,
              localizations,
            ),
          if (hasPhone && hasEmail) const SizedBox(height: 12),
          if (hasEmail)
            _buildContactRow(
              Icons.email,
              localizations?.translate('email') ?? 'Email',
              email,
              localizations,
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, AppLocalizations? localizations) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accentCyan),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full stars
        ...List.generate(fullStars, (index) => const Icon(
          Icons.star,
          color: Colors.amber,
          size: 20,
        )),
        // Half star
        if (hasHalfStar)
          const Icon(
            Icons.star_half,
            color: Colors.amber,
            size: 20,
          ),
        // Empty stars
        ...List.generate(emptyStars, (index) => const Icon(
          Icons.star_border,
          color: Colors.amber,
          size: 20,
        )),
      ],
    );
  }
}

