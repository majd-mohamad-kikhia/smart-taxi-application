import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/services/current_location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/picked_location_model.dart';
import '../../data/models/place_suggestion_model.dart';
import '../../data/repositories/places_repository.dart';

/// Full-screen map picker pushed directly via `Navigator.push` (not
/// through `AppRouter`, which has no support for passing constructor
/// arguments to a route today). Returns a [PickedLocationModel] via
/// `Navigator.pop` when the user confirms, or `null` if they back out.
class LocationPickerScreen extends StatefulWidget {
  final String title;
  final PickedLocationModel? initialLocation;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initialLocation,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(
    AppConstants.defaultMapLat,
    AppConstants.defaultMapLng,
  );
  static const _searchDebounce = Duration(milliseconds: 400);

  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _controller;
  late LatLng _center;
  String? _mapStyle;
  String? _pickedAddress;
  bool _isLocating = false;

  Timer? _debounce;
  List<PlaceSuggestionModel> _suggestions = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    _center = initial != null
        ? LatLng(initial.latitude, initial.longitude)
        : _defaultCenter;
    _pickedAddress = initial?.address;
    if (_pickedAddress != null) {
      _searchController.text = _pickedAddress!;
    } else {
      // `onCameraIdle` never fires for the initial camera position, only
      // after a user-triggered move — without this, confirming the
      // default/untouched pin would carry a null address and fall back
      // to raw coordinates.
      _reverseGeocodeCenter();
    }
    _loadMapStyle();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString(
      'assets/map_styles/dark_map_style.json',
    );
    if (mounted) setState(() => _mapStyle = style);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────
          GoogleMap(
            style: _mapStyle,
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) => _controller = controller,
            onCameraMove: (position) => _center = position.target,
            onCameraIdle: () {
              setState(() {});
              _reverseGeocodeCenter();
            },
            onTap: (_) {
              FocusScope.of(context).unfocus();
              setState(() => _suggestions = []);
            },
          ),
          // ── Fixed center pin ─────────────────────────────
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on_rounded,
                  color: widget.title.contains('انطلاق') ||
                          widget.title.contains('من')
                      ? AppColors.primary
                      : AppColors.accent,
                  size: 44,
                ),
              ),
            ),
          ),
          // ── Top bar: back + title + search ────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _CircularIconButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppConstants.paddingM),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingL,
                            vertical: AppConstants.paddingM,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neutralSurface,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusFull),
                          ),
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  _SearchField(
                    controller: _searchController,
                    isSearching: _isSearching,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  ),
                  if (_suggestions.isNotEmpty || _searchError != null) ...[
                    const SizedBox(height: AppConstants.paddingS),
                    _SuggestionsCard(
                      suggestions: _suggestions,
                      errorMessage: _searchError,
                      onSuggestionTap: _selectSuggestion,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── GPS button ────────────────────────────────────
          Positioned(
            bottom: 160,
            left: AppConstants.paddingL,
            child: FloatingActionButton(
              heroTag: 'location_picker_gps',
              backgroundColor: AppColors.neutralSurface,
              foregroundColor: AppColors.primary,
              onPressed: _isLocating ? null : _useCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          // ── Bottom confirm card ───────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(AppConstants.paddingL),
                padding: const EdgeInsets.all(AppConstants.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurface,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusLarge),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.pin_drop_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: AppConstants.paddingS),
                        Expanded(
                          child: Text(
                            _pickedAddress ??
                                '${_center.latitude.toStringAsFixed(5)}, '
                                    '${_center.longitude.toStringAsFixed(5)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(
                          PickedLocationModel(
                            latitude: _center.latitude,
                            longitude: _center.longitude,
                            address: _pickedAddress,
                          ),
                        ),
                        child: const Text('تأكيد الموقع'),
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() => _searchError = null);
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(_searchDebounce, () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await sl<PlacesRepository>().search(
        query,
        nearLatitude: _center.latitude,
        nearLongitude: _center.longitude,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    } on PlacesException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.message;
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _searchError = null;
    });
  }

  void _selectSuggestion(PlaceSuggestionModel suggestion) {
    FocusScope.of(context).unfocus();
    final target = LatLng(suggestion.latitude, suggestion.longitude);
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(target, 17));
    setState(() {
      _center = target;
      _pickedAddress = suggestion.description;
      _suggestions = [];
      _searchController.text = suggestion.description;
    });
  }

  Future<void> _reverseGeocodeCenter() async {
    final target = _center;
    final address = await sl<PlacesRepository>().addressFor(
      target.latitude,
      target.longitude,
    );
    if (!mounted || _center != target) return;
    setState(() => _pickedAddress = address);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position =
          await sl<CurrentLocationService>().getCurrentLocation();
      final target = LatLng(position.latitude, position.longitude);
      await _controller?.animateCamera(CameraUpdate.newLatLng(target));
      if (mounted) setState(() => _center = target);
    } on LocationPermissionDeniedException catch (e) {
      if (!mounted) return;
      final message = e.reason == LocationFailureReason.serviceDisabled
          ? 'خدمة الموقع غير مفعّلة على جهازك'
          : 'تم رفض إذن الوصول إلى الموقع';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ابحث عن مكان...',
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : (controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                      onPressed: onClear,
                    )
                  : null),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: AppConstants.paddingM),
        ),
      ),
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  final List<PlaceSuggestionModel> suggestions;
  final String? errorMessage;
  final ValueChanged<PlaceSuggestionModel> onSuggestionTap;

  const _SuggestionsCard({
    required this.suggestions,
    required this.errorMessage,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding:
                  const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    suggestion.description,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSuggestionTap(suggestion),
                );
              },
            ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircularIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutralSurface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      ),
    );
  }
}
