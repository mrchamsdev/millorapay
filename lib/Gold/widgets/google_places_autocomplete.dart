import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_colors.dart';

class GooglePlacesAutocompleteWidget extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final String initialValue;
  final Function(Map<String, dynamic>) onPlaceSelected;
  final bool hasError;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final FormFieldValidator<String>? validator;
  final String? countryCode;
  final TextStyle? style;
  final InputDecoration? decoration;

  const GooglePlacesAutocompleteWidget({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Enter location or address',
    this.initialValue = '',
    required this.onPlaceSelected,
    this.hasError = false,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.validator,
    this.countryCode,
    this.style,
    this.decoration,
  });

  @override
  State<GooglePlacesAutocompleteWidget> createState() =>
      _GooglePlacesAutocompleteWidgetState();
}

class _GooglePlacesAutocompleteWidgetState
    extends State<GooglePlacesAutocompleteWidget> {
  late TextEditingController _effectiveController;
  late FocusNode _effectiveFocusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  Timer? _debounceTimer;
  String _lastQuery = '';
  List<Map<String, dynamic>> _lastSuggestions = [];

  String get _apiKey =>
      dotenv.env['GOOGLE_API_KEY'] ??
      'AIzaSyAyw6T1YMpEpkHuwHvUhkhwJQEjorhazZc';

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    } else {
      _effectiveController = widget.controller!;
      if (widget.initialValue.isNotEmpty && _effectiveController.text.isEmpty) {
        _effectiveController.text = widget.initialValue;
      }
    }

    if (widget.focusNode == null) {
      _effectiveFocusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _effectiveFocusNode = widget.focusNode!;
    }

    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _effectiveFocusNode.removeListener(_onFocusChanged);
    if (_ownsController) {
      _effectiveController.dispose();
    }
    if (_ownsFocusNode) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GooglePlacesAutocompleteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryCode != widget.countryCode) {
      _lastQuery = '';
      _lastSuggestions = [];
    }
  }

  void _onFocusChanged() {
    if (!_effectiveFocusNode.hasFocus) {
      // If user typed an address manually and unfocused, geocode it if coordinates not set
      final query = _effectiveController.text.trim();
      if (query.isNotEmpty) {
        _geocodeFallback(query);
      }
    }
  }

  Future<void> _geocodeFallback(String address) async {
    try {
      final queryWithCountry = (widget.countryCode != null && widget.countryCode!.trim().isNotEmpty)
          ? '$address, ${widget.countryCode}'
          : address;
      final locs = await locationFromAddress(queryWithCountry);
      if (locs.isNotEmpty && mounted) {
        widget.onPlaceSelected({
          'location': address,
          'latitude': locs.first.latitude.toString(),
          'longitude': locs.first.longitude.toString(),
          'fullAddress': address,
        });
      }
    } catch (_) {}
  }

  Future<Iterable<Map<String, dynamic>>> _getSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _lastQuery = '';
      _lastSuggestions = [];
      return const Iterable<Map<String, dynamic>>.empty();
    }

    if (trimmed == _lastQuery) {
      return _lastSuggestions;
    }

    final completer = Completer<List<Map<String, dynamic>>>();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final countryParam = (widget.countryCode != null && widget.countryCode!.trim().isNotEmpty)
            ? '&components=country:${widget.countryCode!.trim().toLowerCase()}'
            : '';
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(trimmed)}$countryParam&key=$_apiKey',
        );

        final response = await http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['predictions'] != null) {
            final predictions = (data['predictions'] as List).map((p) {
              final structured = p['structured_formatting'] as Map<String, dynamic>?;
              return {
                'description': p['description'] as String? ?? '',
                'place_id': p['place_id'] as String? ?? '',
                'main_text': structured?['main_text'] as String? ?? (p['description'] as String? ?? ''),
                'secondary_text': structured?['secondary_text'] as String? ?? '',
              };
            }).toList();

            _lastQuery = trimmed;
            _lastSuggestions = predictions;
            if (!completer.isCompleted) completer.complete(predictions);
            return;
          }
        }
      } catch (_) {}

      // Geocoding fallback if Places API returned zero results or timed out
      try {
        final locs = await locationFromAddress(trimmed);
        if (locs.isNotEmpty) {
          final fallbackResults = locs.map((loc) => {
            'description': trimmed,
            'place_id': '',
            'main_text': trimmed,
            'secondary_text': 'Lat: ${loc.latitude.toStringAsFixed(4)}, Lng: ${loc.longitude.toStringAsFixed(4)}',
            'latitude': loc.latitude,
            'longitude': loc.longitude,
          }).toList();

          _lastQuery = trimmed;
          _lastSuggestions = fallbackResults;
          if (!completer.isCompleted) completer.complete(fallbackResults);
          return;
        }
      } catch (_) {}

      _lastQuery = trimmed;
      _lastSuggestions = [];
      if (!completer.isCompleted) completer.complete([]);
    });

    return completer.future;
  }

  Future<void> _handlePlaceSelected(Map<String, dynamic> selection) async {
    final placeId = selection['place_id'] as String? ?? '';
    final description = selection['description'] as String? ?? '';

    _effectiveController.text = description;
    _effectiveFocusNode.unfocus();

    // If coordinates were already supplied from geocoding fallback
    if (selection['latitude'] != null && selection['longitude'] != null) {
      widget.onPlaceSelected({
        'location': description,
        'latitude': selection['latitude'].toString(),
        'longitude': selection['longitude'].toString(),
        'fullAddress': description,
      });
      return;
    }

    if (placeId.isEmpty) {
      await _geocodeFallback(description);
      return;
    }

    // Fetch place details
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,formatted_address,name&key=$_apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final loc = result['geometry']?['location'];
          final double? lat = loc?['lat']?.toDouble();
          final double? lng = loc?['lng']?.toDouble();
          final String formattedAddress =
              result['formatted_address']?.toString() ??
              result['name']?.toString() ??
              description;

          _effectiveController.text = formattedAddress;

          widget.onPlaceSelected({
            'location': formattedAddress,
            if (lat != null) 'latitude': lat.toString(),
            if (lng != null) 'longitude': lng.toString(),
            'fullAddress': formattedAddress,
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback if details API failed
    await _geocodeFallback(description);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Map<String, dynamic>>(
          textEditingController: _effectiveController,
          focusNode: _effectiveFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            return _getSuggestions(textEditingValue.text);
          },
          displayStringForOption: (option) => option['description'] as String? ?? '',
          onSelected: (option) {
            _handlePlaceSelected(option);
          },
          fieldViewBuilder: (
            context,
            controller,
            focusNode,
            onFieldSubmitted,
          ) {
            final defaultDecoration = InputDecoration(
              isDense: true,
              filled: false,
              fillColor: Colors.transparent,
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF1F2F5)),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF1F2F5)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: widget.suffixIcon != null
                  ? (widget.onSuffixIconTap != null
                      ? InkWell(
                          onTap: widget.onSuffixIconTap,
                          child: widget.suffixIcon,
                        )
                      : widget.suffixIcon)
                  : const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 22),
              suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            );

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: widget.style ??
                  const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
              decoration: widget.decoration ?? defaultDecoration,
              validator: widget.validator,
              onFieldSubmitted: (value) {
                onFieldSubmitted();
                final query = value.trim();
                if (query.isNotEmpty) {
                  _geocodeFallback(query);
                }
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final double overlayWidth = constraints.maxWidth > 0
                ? (constraints.maxWidth < 280 ? 280 : constraints.maxWidth)
                : MediaQuery.of(context).size.width - 64;

            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Material(
                  elevation: 6.0,
                  shadowColor: Colors.black26,
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    width: overlayWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF1F2F5),
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        final mainText = option['main_text'] as String? ??
                            option['description'] as String? ??
                            '';
                        final secondaryText =
                            option['secondary_text'] as String? ?? '';

                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            onSelected(option);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.location_on,
                                      color: AppColors.primaryBlue,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        mainText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (secondaryText.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          secondaryText,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
