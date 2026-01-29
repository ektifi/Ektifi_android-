import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class CitySelectionScreen extends StatefulWidget {
  final String? selectedCity;

  const CitySelectionScreen({
    super.key,
    this.selectedCity,
  });

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Static list of Saudi Arabian cities
  final List<String> _cities = [
    'Riyadh',
    'Jeddah',
    'Mecca',
    'Medina',
    'Dammam',
    'Khobar',
    'Taif',
    'Abha',
    'Tabuk',
    'Buraidah',
    'Khamis Mushait',
    'Hail',
    'Najran',
    'Jazan',
    'Al Jubail',
    'Yanbu',
    'Al Khobar',
    'Arar',
    'Sakaka',
    'Jizan',
    'Qatif',
    'Dhahran',
    'Al Kharj',
    'Hafr Al-Batin',
    'Al Qatif',
    'Al Mubarraz',
    'Al Hofuf',
    'Al Bahah',
    'Unaizah',
    'Samtah',
    'Al Qunfudhah',
    'Al Wajh',
    'Al Lith',
    'Al Qassim',
    'Al Majmaah',
    'Al Zulfi',
    'Al Dawadmi',
    'Al Kharj',
    'Al Aflaj',
    'Al Sulayyil',
    'Al Namas',
    'Al Baha',
    'Al Qunfudhah',
    'Al Lith',
    'Al Wajh',
    'Duba',
    'Umluj',
    'Haql',
    'Al Qurayyat',
    'Turaif',
    'Rafha',
    'Al Artawiyah',
    'Al Mithnab',
    'Al Bukayriyah',
    'Al Qaryat',
    'Al Badayea',
    'Al Muzahmiyah',
    'Al Kharj',
    'Al Aflaj',
    'Al Sulayyil',
    'Al Namas',
    'Al Baha',
    'Al Qunfudhah',
    'Al Lith',
    'Al Wajh',
    'Duba',
    'Umluj',
    'Haql',
    'Al Qurayyat',
    'Turaif',
    'Rafha',
    'Al Artawiyah',
    'Al Mithnab',
    'Al Bukayriyah',
    'Al Qaryat',
    'Al Badayea',
    'Al Muzahmiyah',
  ];

  List<String> get _filteredCities {
    if (_searchQuery.isEmpty) {
      return _cities;
    }
    return _cities
        .where((city) =>
            city.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRTL ? Icons.arrow_forward : Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.selectedCity ?? 'Select City',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizations?.translate('search_city') ?? 'Search for your city',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.accentCyan),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          // Cities List
          Expanded(
            child: _filteredCities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations?.translate('no_results') ?? 'No results found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCities.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      final isSelected = city == widget.selectedCity;
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop(city);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  city,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.primaryIndigo
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: AppTheme.primaryIndigo,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

