import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/locale_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../api/login_api.dart';
import '../api/api_service.dart';
import 'transaction_history_screen.dart';
import 'auth/otp_login_screen.dart';
import 'applied_colleges_screen.dart';
import 'wishlist_screen.dart';
import 'institution_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  
  const ProfileScreen({super.key, this.onLocaleChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Method to reload data when tab becomes visible
  void reloadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadWishlist();
    });
  }

  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isLoadingWishlist = false;
  
  // Profile data from API
  String? _username;
  String? _email;
  String? _type;
  
  // Wishlist data from API
  List<Map<String, dynamic>> _wishlistInstitutions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWishlist();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final isLoggedIn = await _authService.isLoggedIn();
    
    if (isLoggedIn) {
      // Get token and fetch profile from API
      final token = await _authService.getToken();
      if (token != null) {
        final profileResult = await LoginApi.getProfile(token: token);
        
        if (profileResult['status'] == true && profileResult['data'] != null) {
          final data = profileResult['data'] as Map<String, dynamic>;
          _username = data['username'] as String?;
          _email = data['email'] as String?;
          _type = data['type'] as String?;
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
      // Reload wishlist when login status changes
      if (isLoggedIn) {
        _loadWishlist();
      } else {
        setState(() {
          _wishlistInstitutions = [];
        });
      }
    }
  }

  Future<void> _logout() async {
    final localizations = AppLocalizations.of(context);
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.translate('logout') ?? 'Logout'),
        content: Text(localizations?.translate('are_you_sure_logout') ?? 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              localizations?.translate('logout') ?? 'Logout',
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await _authService.logout();
      CustomSnackBar.showSuccess(
        context,
        localizations?.translate('logout_successful') ?? 'Logged out successfully',
      );
      // Clear profile data
      setState(() {
        _username = null;
        _email = null;
        _type = null;
        _wishlistInstitutions = [];
      });
      await _loadUserData();
      await _loadWishlist();
    }
  }

  // Get applied institutions data (first 5 schools and 5 colleges)
  List<Map<String, dynamic>> get _appliedInstitutions {
    // Using the same data structure as applied_colleges_screen
    return [
      {
        'name': 'Al-Faisal International School',
        'logo': 'assets/images/Al-Faisal International School.avif',
      },
      {
        'name': 'Riyadh Schools',
        'logo': 'assets/images/Riyadh Schools.png',
      },
      {
        'name': 'British International School',
        'logo': 'assets/images/British International School.png',
      },
      {
        'name': 'Al-Noor Girls School',
        'logo': 'assets/images/Al-Noor Girls School.png',
      },
      {
        'name': 'Indian International School',
        'logo': 'assets/images/Indian International School.png',
      },
      {
        'name': 'King Saud University',
        'logo': 'assets/images/King Saud University.jpeg',
      },
      {
        'name': 'King Fahd University of Petroleum & Minerals',
        'logo': 'assets/images/King Fahd University of Petroleum & Minerals.png',
      },
      {
        'name': 'Princess Nourah bint Abdulrahman University',
        'logo': 'assets/images/Princess Nourah bint Abdulrahman University.png',
      },
      {
        'name': 'King Abdulaziz University',
        'logo': 'assets/images/King Abdulaziz University.jpeg',
      },
      {
        'name': 'Imam Muhammad ibn Saud Islamic University',
        'logo': 'assets/images/Imam Muhammad ibn Saud Islamic University.png',
      },
    ];
  }

  Future<void> _loadWishlist() async {
    try {
      setState(() {
        _isLoadingWishlist = true;
      });

      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _wishlistInstitutions = [];
          _isLoadingWishlist = false;
        });
        return;
      }

      final wishlistItems = await ApiService.getWishlist(token: token);
      
      // Transform API data to match expected format (limit to first 6 for preview)
      final transformedItems = wishlistItems.take(6).map((item) {
        // API might return institution nested in item or directly
        final institution = item['institution'] as Map<String, dynamic>? ?? item;
        return institution;
      }).toList();

      if (mounted) {
        setState(() {
          _wishlistInstitutions = transformedItems;
          _isLoadingWishlist = false;
        });
      }
    } catch (e) {
      print('Error loading wishlist: $e');
      if (mounted) {
        setState(() {
          _wishlistInstitutions = [];
          _isLoadingWishlist = false;
        });
      }
    }
  }

  String _getNameKey(String name) {
    final nameMap = {
      'Al-Faisal International School': 'al_faisal_international_school',
      'Riyadh Schools': 'riyadh_schools',
      'British International School': 'british_international_school',
      'Al-Noor Girls School': 'al_noor_girls_school',
      'Indian International School': 'indian_international_school',
      'King Saud University': 'king_saud_university',
      'King Fahd University of Petroleum & Minerals': 'king_fahd_university_petroleum',
      'Princess Nourah bint Abdulrahman University': 'princess_nourah_university',
      'King Abdulaziz University': 'king_abdulaziz_university',
      'Imam Muhammad ibn Saud Islamic University': 'imam_muhammad_university',
    };
    return nameMap[name] ?? name.toLowerCase().replaceAll(' ', '_');
  }

  Future<void> _changeLanguage(Locale locale) async {
    if (locale == Localizations.localeOf(context)) {
      return; // Already selected
    }
    
    // Save the locale
    await LocaleService.saveLocale(locale);
    
    // Notify parent about locale change
    if (widget.onLocaleChanged != null) {
      widget.onLocaleChanged!(locale);
    }
    
    // Force rebuild
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildInstitutionCard(
    BuildContext context,
    Map<String, dynamic> institution,
    AppLocalizations? localizations,
    {bool isWishlist = false}
  ) {
    // Handle both API format (institution_name) and local format (name)
    final institutionName = institution['institution_name'] as String? ?? 
                           institution['name'] as String? ?? 
                           'Unknown';
    final nameKey = _getNameKey(institutionName);
    final displayName = localizations?.translate(nameKey) ?? institutionName;
    
    // Get institution ID for navigation
    final institutionId = institution['id'] is int 
        ? institution['id'] as int
        : (institution['id'] != null ? int.tryParse(institution['id'].toString()) : null);
    
    // Get first character for logo/avatar
    final firstChar = institutionName.isNotEmpty ? institutionName[0].toUpperCase() : '?';
    
    return InkWell(
      onTap: () {
        // Navigate to institution details screen
        if (institutionId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InstitutionDetailsScreen(
                institutionId: institutionId,
                institution: institution,
                hideApplyButton: false,
              ),
            ),
          );
        } else if (isWishlist) {
          // Fallback to wishlist screen if no ID
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const WishlistScreen(),
            ),
          );
        } else {
          // Fallback to applied colleges screen if no ID
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AppliedCollegesScreen(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryIndigo.withOpacity(0.1),
                border: Border.all(
                  color: AppTheme.primaryIndigo.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  firstChar,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryIndigo,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final localizations = AppLocalizations.of(context);

    return KeyedSubtree(
      key: ValueKey(currentLocale.languageCode),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            localizations?.translate('profile') ?? 'Profile',
            style: const TextStyle(
              color: AppTheme.primaryIndigo,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            // Language Selection
            PopupMenuButton<Locale>(
              icon: const Icon(
                Icons.language,
                color: Colors.black87,
                size: 24,
              ),
              onSelected: (Locale locale) async {
                await _changeLanguage(locale);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<Locale>(
                  value: const Locale('en'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Text(
                            localizations?.translate('english') ?? 'English',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (currentLocale.languageCode == 'en')
                        const Icon(
                          Icons.check,
                          color: AppTheme.primaryIndigo,
                          size: 20,
                        ),
                    ],
                  ),
                ),
                PopupMenuItem<Locale>(
                  value: const Locale('ar'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🇸🇦', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Text(
                            localizations?.translate('arabic') ?? 'Arabic',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (currentLocale.languageCode == 'ar')
                        const Icon(
                          Icons.check,
                          color: AppTheme.primaryIndigo,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24.0),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
                            child: _isLoggedIn && _username != null
                                ? Text(
                                    _username!.isNotEmpty
                                        ? _username![0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryIndigo,
                                    ),
                                  )
                                : Icon(
                        Icons.person,
                        size: 25,
                        color: AppTheme.primaryIndigo,
                      ),
                    ),
                    const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isLoggedIn && _username != null) ...[
                                  Text(
                                    _username!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (_email != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _email!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  if (_type != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryIndigo.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _type!.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.primaryIndigo,
                                        ),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                    Text(
                                    localizations?.translate('guest_user') ?? 'Guest User',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Applied Colleges Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations?.translate('applied_colleges') ?? 'Applied Colleges',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to applied colleges screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AppliedCollegesScreen(),
                              ),
                            );
                          },
                          child: Text(
                            localizations?.translate('view_all') ?? 'View All',
                            style: TextStyle(
                              color: AppTheme.primaryIndigo,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _appliedInstitutions.map((institution) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildInstitutionCard(context, institution, localizations, isWishlist: false),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Wishlist Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations?.translate('wishlist') ?? 'Wishlist',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to wishlist screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WishlistScreen(),
                              ),
                            );
                          },
                          child: Text(
                            localizations?.translate('view_all') ?? 'View All',
                            style: TextStyle(
                              color: AppTheme.primaryIndigo,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: _isLoadingWishlist
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _wishlistInstitutions.isEmpty
                          ? Center(
                              child: Text(
                                localizations?.translate('wishlist_empty') ?? 'Your wishlist is empty',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : ListView.builder(
                        scrollDirection: Axis.horizontal,
                              itemCount: _wishlistInstitutions.length,
                              itemBuilder: (context, index) {
                                if (index >= _wishlistInstitutions.length) {
                                  return const SizedBox.shrink();
                                }
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                                  child: _buildInstitutionCard(
                                    context, 
                                    _wishlistInstitutions[index], 
                                    localizations, 
                                    isWishlist: true
                                  ),
                          );
                              },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Menu Options
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.history,
                        color: AppTheme.primaryIndigo,
                      ),
                      title: Text(
                        localizations?.translate('transaction_history') ?? 'Transaction History',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // trailing: Icon(
                      //   isRTL ? Icons.arrow_back : Icons.arrow_forward,
                      //   color: Colors.grey[400],
                      // ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransactionHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    if (_isLoggedIn)
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: AppTheme.errorRed,
                        ),
                        title: Text(
                          localizations?.translate('logout') ?? 'Logout',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.errorRed,
                          ),
                        ),
                        onTap: _logout,
                      )
                    else
                    ListTile(
                      leading: Icon(
                        Icons.login,
                        color: AppTheme.primaryIndigo,
                      ),
                      title: Text(
                        localizations?.translate('login') ?? 'Login',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const OTPLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
