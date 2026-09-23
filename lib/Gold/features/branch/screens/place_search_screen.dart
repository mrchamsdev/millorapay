import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';

class PlaceSearchScreen extends StatefulWidget {
  final String? countryCode;
  const PlaceSearchScreen({super.key, this.countryCode});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placesList = [];
  bool _isLoading = false;
  Timer? _debounce;

  String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? 'AIzaSyAyw6T1YMpEpkHuwHvUhkhwJQEjorhazZc';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _getSuggestions(input);
    });
  }

  Future<void> _getSuggestions(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      if (mounted) setState(() => _placesList = []);
      return;
    }

    setState(() => _isLoading = true);

    final countryParam = (widget.countryCode != null && widget.countryCode!.trim().isNotEmpty)
        ? '&components=country:${widget.countryCode!.trim().toLowerCase()}'
        : '';
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(trimmed)}$countryParam&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List? ?? [];
        if (mounted) {
          setState(() {
            _placesList = predictions;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback using geocoding package if Places API fails
    try {
      final locations = await locationFromAddress(trimmed);
      if (locations.isNotEmpty && mounted) {
        setState(() {
          _placesList = locations.map((loc) => {
            'isGeocode': true,
            'description': trimmed,
            'lat': loc.latitude,
            'lng': loc.longitude,
            'structured_formatting': {
              'main_text': trimmed,
              'secondary_text': '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
            }
          }).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _placesList = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPlace(dynamic place) async {
    // If it was from fallback geocode:
    if (place['isGeocode'] == true) {
      final lat = place['lat'] as double;
      final lng = place['lng'] as double;
      final desc = place['description']?.toString() ?? '';
      Navigator.pop(context, {
        'latLng': LatLng(lat, lng),
        'address': desc,
      });
      return;
    }

    final placeId = place['place_id']?.toString();
    final description = place['description']?.toString() ?? '';

    if (placeId == null || placeId.isEmpty) {
      Navigator.pop(context, {
        'address': description,
      });
      return;
    }

    setState(() => _isLoading = true);

    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,formatted_address,name&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        final loc = result?['geometry']?['location'];
        if (loc != null) {
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final address = result['formatted_address']?.toString() ?? description;
          if (mounted) {
            Navigator.pop(context, {
              'latLng': LatLng(lat, lng),
              'address': address,
            });
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback: try geocoding the description
    try {
      final locations = await locationFromAddress(description);
      if (locations.isNotEmpty && mounted) {
        Navigator.pop(context, {
          'latLng': LatLng(locations.first.latitude, locations.first.longitude),
          'address': description,
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context, {
        'address': description,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const GoldBackButton(),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Search city, area, or landmark...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _getSuggestions('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                ),
              ),
            )
          else if (_placesList.isNotEmpty)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _placesList.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final place = _placesList[index];
                  final formatting = place['structured_formatting'] as Map? ?? {};
                  final mainText = formatting['main_text']?.toString() ?? place['description']?.toString() ?? '';
                  final secondaryText = formatting['secondary_text']?.toString() ?? '';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on, color: AppColors.primaryBlue, size: 20),
                      ),
                    ),
                    title: Text(
                      mainText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: secondaryText.isNotEmpty
                        ? Text(
                            secondaryText,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () => _selectPlace(place),
                  );
                },
              ),
            )
          else if (_searchController.text.trim().isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No locations found. Try searching a different place.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 48, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 12),
                    Text(
                      'Search for your branch address or area',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
