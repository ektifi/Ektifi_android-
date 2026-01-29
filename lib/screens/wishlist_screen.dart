import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../api/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';
import 'institution_details_screen.dart';

enum InstitutionType {
  schools,
  colleges,
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _wishlistInstitutions = [];
  bool _isLoading = true;
  String? _errorMessage;
  final AuthService _authService = AuthService();
  bool _hasLoaded = false;

  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  @override
  void initState() {
    super.initState();
    // Load data when screen is first created
    if (!_hasLoaded) {
      _loadWishlist();
    }
  }

  // Method to reload wishlist data
  Future<void> refreshWishlist() async {
    _hasLoaded = false;
    await _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view your wishlist';
        });
        return;
      }

      final wishlistItems = await ApiService.getWishlist(token: token);
      
      // Transform API data to match expected format
      final transformedItems = wishlistItems.map((item) {
        // API might return institution nested in item or directly
        final institution = item['institution'] as Map<String, dynamic>? ?? item;
        return institution;
      }).toList();

      if (mounted) {
        setState(() {
          _wishlistInstitutions = transformedItems;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading wishlist: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load wishlist. Please try again.';
        });
      }
    }
  }

  Future<void> _removeFromWishlist(int institutionId, String institutionName) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        CustomSnackBar.showError(
          context,
          'Please login to remove from wishlist',
        );
        return;
      }

      // Show confirmation dialog
      final localizations = AppLocalizations.of(context);
      final shouldRemove = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations?.translate('remove_from_wishlist') ?? 'Remove from Wishlist'),
          content: Text(
            localizations?.translate('are_you_sure_remove_wishlist') ?? 
            'Are you sure you want to remove "$institutionName" from your wishlist?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations?.translate('cancel') ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                localizations?.translate('remove') ?? 'Remove',
                style: const TextStyle(color: AppTheme.errorRed),
              ),
            ),
          ],
        ),
      );

      if (shouldRemove != true) {
        return;
      }

      // Remove from wishlist via API
      await ApiService.removeFromWishlist(
        institutionId: institutionId,
        token: token,
      );

      // Remove from local list
      if (mounted) {
        setState(() {
          _wishlistInstitutions.removeWhere(
            (item) {
              final id = item['id'] is int 
                  ? item['id'] as int
                  : (item['id'] != null ? int.tryParse(item['id'].toString()) : null);
              return id == institutionId;
            },
          );
        });

        CustomSnackBar.showSuccess(
          context,
          localizations?.translate('removed_from_wishlist') ?? 'Removed from wishlist',
        );
        
        // Reload wishlist to refresh the list
        await _loadWishlist();
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'Failed to remove from wishlist. Please try again.',
        );
      }
    }
  }

  // Helper method to get first character of institution name
  String _getFirstCharacter(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  // Helper method to convert institution name to translation key
  String _getNameKey(String name) {
    final nameMap = {
      'Al-Faisal International School': 'al_faisal_international_school',
      'Riyadh Schools': 'riyadh_schools',
      'British International School': 'british_international_school',
      'Al-Noor Girls School': 'al_noor_girls_school',
      'King Fahd School': 'king_fahd_school',
      'King Saud University': 'king_saud_university',
      'King Fahd University of Petroleum & Minerals': 'king_fahd_university_petroleum',
      'Princess Nourah bint Abdulrahman University': 'princess_nourah_university',
      'King Abdulaziz University': 'king_abdulaziz_university',
      'Alfaisal University': 'alfaisal_university',
    };
    return nameMap[name] ?? name.toLowerCase().replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final currentLocale = Localizations.localeOf(context);
    final localizations = AppLocalizations.of(context);

    // Reload data when screen becomes visible (if not already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoaded && !_isLoading) {
        _loadWishlist();
      }
    });

    return KeyedSubtree(
      key: ValueKey(currentLocale.languageCode),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            localizations?.translate('wishlist') ?? 'Wishlist',
            style: const TextStyle(
              color: AppTheme.primaryIndigo,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadWishlist,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _wishlistInstitutions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations?.translate('no_wishlist_items') ?? 'No wishlist items',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  children: _wishlistInstitutions
                      .map((institution) => _buildVerticalInstitutionCard(
                          context, institution, localizations))
                      .toList(),
                ),
        ),
      ),
    );
  }

  // Vertical card for wishlist institutions (same format as home screen)
  Widget _buildVerticalInstitutionCard(
    BuildContext context,
    Map<String, dynamic> institution,
    AppLocalizations? localizations,
  ) {
    // Handle both API format (institution_name) and local format (name)
    final institutionName = institution['institution_name'] as String? ?? 
                           institution['name'] as String? ?? 
                           'Unknown';
    final nameKey = _getNameKey(institutionName);
    final displayName = localizations?.translate(nameKey) ?? institutionName;
    
    // Get rating from API data (avg_rating) or local data (rating)
    final rating = institution['avg_rating'] != null
        ? double.tryParse(institution['avg_rating'].toString()) ?? 0.0
        : (institution['rating'] as num?)?.toDouble() ?? 0.0;
    
    // Get total reviews
    final totalReviews = institution['total_reviews'] as int? ?? 
                        institution['reviews'] as int? ?? 0;
    
    // Get city
    final city = institution['city'] as String? ?? 
                (institution['location'] as Map<String, dynamic>?)?['city'] as String? ??
                ((institution['about'] as Map<String, dynamic>?)?['contact'] as Map<String, dynamic>?)?['city'] as String? ?? '';
    
    // Get first character for logo
    final firstChar = _getFirstCharacter(institutionName);
    
    // Get institution ID for removal
    final institutionId = institution['id'] is int 
        ? institution['id'] as int
        : (institution['id'] != null ? int.tryParse(institution['id'].toString()) : null);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo/Avatar
          InkWell(
          onTap: () {
              Navigator.push(
                context,
              MaterialPageRoute(
                builder: (context) => InstitutionDetailsScreen(
                    institutionId: institutionId,
                  institution: institution,
                  hideApplyButton: false,
                ),
              ),
            );
          },
            borderRadius: BorderRadius.circular(50),
            child: Container(
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
                ),
          const SizedBox(width: 12),
                // Institution Details
                Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstitutionDetailsScreen(
                      institutionId: institutionId,
                      institution: institution,
                      hideApplyButton: false,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    displayName,
                              style: const TextStyle(
                      fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                      ),
                  const SizedBox(height: 4),
                  if (rating > 0) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                          size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (totalReviews > 0) ...[
                          Text(
                            ' ($totalReviews)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (city.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  ],
              ],
            ),
          ),
        ),
          // Heart icon to remove from wishlist
          if (institutionId != null)
            IconButton(
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 28,
              ),
              onPressed: () => _removeFromWishlist(institutionId, institutionName),
              tooltip: localizations?.translate('remove_from_wishlist') ?? 'Remove from wishlist',
            ),
        ],
      ),
    );
  }
}

