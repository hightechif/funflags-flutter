import 'package:flutter/material.dart';
import 'package:funflags/data/repositories/country_repository_impl.dart';
import 'package:funflags/domain/models/country.dart';
import 'package:funflags/domain/repositories/country_repository.dart';

class FlagsScreen extends StatefulWidget {
  const FlagsScreen({super.key});

  @override
  State<FlagsScreen> createState() => _FlagsScreenState();
}

class _FlagsScreenState extends State<FlagsScreen> {
  late final CountryRepository _countryRepository;

  String _selectedRegion = 'World';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Country> _countries = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _hasMore = true;

  // Scroll controller for endless scrolling
  final ScrollController _scrollController = ScrollController();

  // Search mode
  bool _isSearchMode = false;
  List<Country> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _countryRepository = CountryRepositoryImpl();
    _loadCountries();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more when user is 200px from bottom
        if (!_isLoadingMore && _hasMore && !_isSearchMode) {
          _loadMoreCountries();
        }
      }
    });
  }

  Future<void> _loadCountries({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _countries.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final result = await _countryRepository.getCountries(
        region: _selectedRegion == 'World' ? null : _selectedRegion,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        if (refresh) {
          _countries = result.items;
        } else {
          _countries.addAll(result.items);
        }
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading countries: $e')));
      }
    }
  }

  Future<void> _loadMoreCountries() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final result = await _countryRepository.getCountries(
        region: _selectedRegion == 'World' ? null : _selectedRegion,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _countries.addAll(result.items);
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Rollback page increment on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more countries: $e')),
        );
      }
    }
  }

  void _changeRegion(String region) {
    setState(() {
      _selectedRegion = region;
      _searchController.clear();
      _searchQuery = '';
      _isSearchMode = false;
      _searchResults.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    _loadCountries(refresh: true);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearchMode = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearchMode = true;
      _isLoading = true;
    });

    try {
      final results = await _countryRepository.searchCountries(
        query,
        region: _selectedRegion == 'World' ? null : _selectedRegion,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching countries: $e')),
        );
      }
    }
  }

  List<Country> get _displayedCountries {
    return _isSearchMode ? _searchResults : _countries;
  }

  Future<void> _refreshCountries() async {
    await _countryRepository.clearCache();
    _changeRegion(_selectedRegion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Flags'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCountries,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Region selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 8),
                _buildRegionChip('World'),
                _buildRegionChip('Africa'),
                _buildRegionChip('Americas'),
                _buildRegionChip('Asia'),
                _buildRegionChip('Europe'),
                _buildRegionChip('Oceania'),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search countries...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _performSearch(value);
              },
            ),
          ),

          // Countries count indicator
          if (!_isLoading && _displayedCountries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    _isSearchMode
                        ? '${_searchResults.length} countries found'
                        : '${_countries.length} countries loaded',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (!_isSearchMode && _hasMore) ...[
                    const Spacer(),
                    Text(
                      'Scroll for more',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Flag list
          Expanded(
            child:
                _isLoading && _countries.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _displayedCountries.isEmpty
                    ? Center(
                      child: Text(
                        _isSearchMode
                            ? 'No countries found for "$_searchQuery"'
                            : 'No countries available',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _refreshCountries,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            _displayedCountries.length +
                            (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show loading indicator at the bottom
                          if (index == _displayedCountries.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final country = _displayedCountries[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              leading: Hero(
                                tag: 'flag_${country.code}',
                                child: SizedBox(
                                  width: 60,
                                  height: 40,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      country.flagUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                country.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(country.continent),
                              trailing: Text(country.code),
                              onTap: () {
                                _showCountryDetails(country);
                              },
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionChip(String region) {
    final isSelected = _selectedRegion == region;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(region),
        selected: isSelected,
        onSelected: (_) {
          _changeRegion(region);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showCountryDetails(Country country) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Center(
                  child: Hero(
                    tag: 'flag_${country.code}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(country.flagUrl, height: 120),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    country.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Country Code', country.code),
                _buildInfoRow('Continent', country.continent),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
