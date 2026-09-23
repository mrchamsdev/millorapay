import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/country_utility.dart';
import '../../../widgets/gold_back_button.dart';
import 'place_search_screen.dart';

class MapSelectionScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocation;
  final String? countryCode;

  const MapSelectionScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocation,
    this.countryCode,
  });

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(17.3850, 78.4867); // Default Hyderabad
  bool _isLoading = true;
  bool _isMoving = false;
  String _addressText = 'Fetching selected location...';
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _determineInitialLocation();
  }

  Future<void> _determineInitialLocation() async {
    try {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _currentPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
        if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
          _addressText = widget.initialLocation!;
        }
        if (mounted) setState(() => _isLoading = false);
        _reverseGeocode(_currentPosition);
        return;
      }

      // Try device GPS location
      Position? position = await _locationService.getPosition();
      if (position != null) {
        _currentPosition = LatLng(position.latitude, position.longitude);
      } else if (widget.countryCode != null && widget.countryCode!.trim().isNotEmpty) {
        final coords = CountryUtility.getDefaultCoordinates(widget.countryCode);
        _currentPosition = LatLng(coords.$1, coords.$2);
      }
    } catch (_) {
      if (widget.countryCode != null && widget.countryCode!.trim().isNotEmpty) {
        final coords = CountryUtility.getDefaultCoordinates(widget.countryCode);
        _currentPosition = LatLng(coords.$1, coords.$2);
      }
    }

    if (mounted) setState(() => _isLoading = false);
    _reverseGeocode(_currentPosition);
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final formatted = await _locationService.getAddressFormatting(
        latLng.latitude,
        latLng.longitude,
      );

      if (mounted) {
        setState(() {
          _addressText = (formatted != null && formatted.isNotEmpty)
              ? formatted
              : 'Lat: ${latLng.latitude.toStringAsFixed(5)}, Lng: ${latLng.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addressText =
              'Lat: ${latLng.latitude.toStringAsFixed(5)}, Lng: ${latLng.longitude.toStringAsFixed(5)}';
        });
      }
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
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaceSearchScreen(countryCode: widget.countryCode)),
              );

              if (result is Map) {
                LatLng? targetLatLng;
                if (result['latLng'] is LatLng) {
                  targetLatLng = result['latLng'] as LatLng;
                } else if (result['address'] != null) {
                  try {
                    final locs = await locationFromAddress(result['address'].toString());
                    if (locs.isNotEmpty) {
                      targetLatLng = LatLng(locs.first.latitude, locs.first.longitude);
                    }
                  } catch (_) {}
                }

                if (targetLatLng != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: targetLatLng, zoom: 16.5),
                    ),
                  );
                  setState(() {
                    _currentPosition = targetLatLng!;
                    if (result['address'] != null) {
                      _addressText = result['address'];
                    }
                  });
                  _reverseGeocode(targetLatLng);
                }
              }
            },
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search location...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 16.0,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  onCameraMoveStarted: () {
                    if (!_isMoving) {
                      setState(() => _isMoving = true);
                    }
                  },
                  onCameraMove: (position) {
                    _currentPosition = position.target;
                  },
                  onCameraIdle: () {
                    setState(() => _isMoving = false);
                    _reverseGeocode(_currentPosition);
                  },
                ),

                // Center Pin Icon with Bounce effect
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 38),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      transform: Matrix4.translationValues(0, _isMoving ? -14 : 0, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // "My Location" Floating Action Button
                Positioned(
                  right: 16,
                  bottom: 230,
                  child: FloatingActionButton(
                    heroTag: 'myLocationBtn',
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () async {
                      Position? position = await _locationService.getPosition();
                      if (position != null) {
                        final latLng = LatLng(position.latitude, position.longitude);
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: latLng, zoom: 16.5),
                          ),
                        );
                        setState(() => _currentPosition = latLng);
                        _reverseGeocode(latLng);
                      }
                    },
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                ),

                // Bottom Panel
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.place,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Selected Branch Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _addressText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lat: ${_currentPosition.latitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lng: ${_currentPosition.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, {
                                  'location': _addressText,
                                  'latitude': _currentPosition.latitude,
                                  'longitude': _currentPosition.longitude,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Confirm & Select Location',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
