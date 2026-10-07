import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../data/models/place_suggestion_model.dart';
import '../../data/repositories/places_repository.dart';
import '../widgets/address_details_field_widget.dart';
import '../widgets/place_search_field_widget.dart';
import '../widgets/place_suggestions_card_widget.dart';

/// Full-screen map picker, pushed directly by the order screen and through
/// `AppRouter.locationPicker` by other features. Returns a
/// [PickedLocationModel] (with the optional address details typed under the
/// address) via `Navigator.pop` when the user confirms, or `null` if they
/// back out.
class LocationPickerScreen extends StatefulWidget {
  final String title;

  /// Pickup picks use the primary pin color, drop-off the accent one.
  final bool isPickup;
  final PickedLocationModel? initialLocation;

  const LocationPickerScreen({
    super.key,
    required this.title,
    required this.isPickup,
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
  static const _maxDetailsLength = 255;

  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _detailsController = TextEditingController(
    text: widget.initialLocation?.addressDetails ?? '',
  );

  GoogleMapController? _controller;
  late LatLng _center;

  /// Where the customer actually is (not where the map is looking) — what
  /// "nearest first" is measured from. Null until a fix is had, e.g. when
  /// location permission is off; the search then uses the map's center.
  LatLng? _userLocation;

  /// A GPS fix that arrived before the map was created.
  LatLng? _pendingTarget;
  String? _mapStyle;
  String? _pickedAddress;

  /// A reverse-geocode for the current pin is in flight.
  bool _isResolvingAddress = false;

  /// The place last chosen from the search list. It already is a real
  /// address, so it stands in if the reverse lookup for that same spot
  /// fails.
  PlaceSuggestionModel? _selectedSuggestion;
  bool _isLocating = false;

  /// Confirming is only allowed once the pin has a real, resolved address
  /// — never a bare coordinate pair, and never a stale address left over
  /// from a previous pin position.
  bool get _canConfirm => _pickedAddress != null && !_isResolvingAddress;

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
    } else if (widget.isPickup) {
      // The customer is almost always at the pickup: start there instead of
      // on the default city centre.
      _isResolvingAddress = true;
      _startAtCurrentLocation();
    } else {
      // `onCameraIdle` never fires for the initial camera position, only
      // after a user-triggered move — without this, confirming the
      // default/untouched pin would carry a null address and fall back
      // to raw coordinates.
      _reverseGeocodeCenter();
    }
    _loadMapStyle();
    unawaited(_loadUserLocation());
  }

  /// Reads the customer's position for the search ranking. Quiet: it never
  /// asks for permission (the pickup flow does that itself), and it never
  /// overwrites a fix `_useCurrentLocation` already got, which is fresher.
  Future<void> _loadUserLocation() async {
    final position = await sl<CurrentLocationService>().getPositionIfAllowed();
    if (position != null) {
      _userLocation ??= LatLng(position.latitude, position.longitude);
    }
  }

  /// Moves the pin to the customer's GPS position, quietly: no message if it
  /// can't (permission off, no signal) — the map just stays on the default
  /// centre and resolves that address instead.
  Future<void> _startAtCurrentLocation() async {
    await _useCurrentLocation(silent: true);
    if (mounted && _center == _defaultCenter && !_isLocating) {
      _reverseGeocodeCenter();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _detailsController.dispose();
    // Drop the reference so no late async callback can reach a controller
    // whose GoogleMap widget is gone.
    _controller = null;
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
          GoogleMap(
            style: _mapStyle,
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _controller = controller;
              final pending = _pendingTarget;
              if (pending != null) {
                _pendingTarget = null;
                controller.moveCamera(CameraUpdate.newLatLng(pending));
              }
            },
            onCameraMove: (position) {
              _center = position.target;
              // The old address belongs to the old pin position; drop it
              // right away so it can't be confirmed for the new one.
              if (_pickedAddress != null) {
                setState(() => _pickedAddress = null);
              }
            },
            onCameraIdle: () {
              setState(() {});
              _reverseGeocodeCenter();
            },
            onTap: (_) {
              FocusScope.of(context).unfocus();
              setState(() => _suggestions = []);
            },
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on_rounded,
                  color: widget.isPickup ? AppColors.primary : AppColors.accent,
                  size: 44,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _CircularIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
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
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusFull,
                            ),
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
                  Row(
                    children: [
                      Expanded(
                        child: PlaceSearchFieldWidget(
                          controller: _searchController,
                          isSearching: _isSearching,
                          onChanged: _onSearchChanged,
                          onClear: _clearSearch,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingM),
                      _CircularIconButton(
                        icon: Icons.my_location_rounded,
                        iconColor: AppColors.primary,
                        padding: 13,
                        isLoading: _isLocating,
                        onTap: _isLocating ? null : _useCurrentLocation,
                      ),
                    ],
                  ),
                  if (_suggestions.isNotEmpty || _searchError != null) ...[
                    const SizedBox(height: AppConstants.paddingS),
                    PlaceSuggestionsCardWidget(
                      suggestions: _suggestions,
                      errorMessage: _searchError,
                      onSuggestionTap: _selectSuggestion,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(AppConstants.paddingL),
                padding: const EdgeInsets.all(AppConstants.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
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
                                (_isResolvingAddress
                                    ? context.l10n.locationResolving
                                    : context.l10n.locationUnresolved),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _pickedAddress != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (_pickedAddress == null && !_isResolvingAddress)
                          TextButton(
                            onPressed: _reverseGeocodeCenter,
                            child: Text(context.l10n.retry),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    AddressDetailsFieldWidget(
                      controller: _detailsController,
                      maxLength: _maxDetailsLength,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canConfirm ? _confirm : null,
                        child: Text(context.l10n.confirmLocation),
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

  void _confirm() {
    final details = _detailsController.text.trim();
    Navigator.of(context).pop(
      PickedLocationModel(
        latitude: _center.latitude,
        longitude: _center.longitude,
        address: _pickedAddress,
        addressDetails: details.isEmpty ? null : details,
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() => _searchError = null);
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(_searchDebounce, () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    // Nearest to the customer; the map's center only when their position
    // isn't known.
    final near = _userLocation ?? _center;
    try {
      final results = await sl<PlacesRepository>().search(
        query,
        nearLatitude: near.latitude,
        nearLongitude: near.longitude,
      );
      // The customer typed on (or cleared the box) while this ran: a
      // newer search owns the list now, and an older answer must not
      // replace it.
      if (!mounted || query != _searchController.text) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    } on PlacesException catch (e) {
      if (!mounted || query != _searchController.text) return;
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
      _isSearching = false;
    });
  }

  void _selectSuggestion(PlaceSuggestionModel suggestion) {
    FocusScope.of(context).unfocus();
    final target = LatLng(suggestion.latitude, suggestion.longitude);
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(target, 17));
    setState(() {
      _selectedSuggestion = suggestion;
      _center = target;
      _pickedAddress = suggestion.description;
      _suggestions = [];
      _searchController.text = suggestion.description;
    });
  }

  Future<void> _reverseGeocodeCenter() async {
    final target = _center;
    setState(() {
      _pickedAddress = null;
      _isResolvingAddress = true;
    });
    final address = await sl<PlacesRepository>().addressFor(
      target.latitude,
      target.longitude,
    );
    // The pin moved on while this lookup ran; the newer lookup owns the
    // state now.
    if (!mounted || _center != target) return;
    setState(() {
      _pickedAddress = address ?? _selectedSuggestionAddressAt(target);
      _isResolvingAddress = false;
    });
  }

  /// The chosen suggestion's address, if the pin is still on that place
  /// (within a few meters — the camera may settle a hair off).
  String? _selectedSuggestionAddressAt(LatLng target) {
    final suggestion = _selectedSuggestion;
    if (suggestion == null) return null;
    const tolerance = 0.0001;
    final isSamePlace =
        (suggestion.latitude - target.latitude).abs() < tolerance &&
        (suggestion.longitude - target.longitude).abs() < tolerance;
    return isSamePlace ? suggestion.description : null;
  }

  /// [silent] is the automatic try on opening: it never shows a message, and
  /// it leaves the map alone if the customer has already moved it or searched.
  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() => _isLocating = true);
    try {
      final position = await sl<CurrentLocationService>().getCurrentLocation();
      // The GPS fix can arrive after the user has left this screen, at
      // which point the map (and its controller) is already disposed.
      if (!mounted) return;
      final target = LatLng(position.latitude, position.longitude);
      _userLocation = target;
      if (silent &&
          (_center != _defaultCenter || _searchController.text.isNotEmpty)) {
        return;
      }
      final controller = _controller;
      if (controller == null) {
        // The map isn't built yet; `onMapCreated` moves it there.
        _pendingTarget = target;
        _center = target;
        return;
      }
      await controller.animateCamera(CameraUpdate.newLatLng(target));
      if (mounted) setState(() => _center = target);
    } on LocationPermissionDeniedException catch (e) {
      if (!mounted || silent) return;
      final message = e.reason == LocationFailureReason.serviceDisabled
          ? context.l10n.errLocationServiceOff
          : context.l10n.errLocationDenied;
      showAppSnackBar(context, message, type: AppSnackBarType.warning);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;

  /// `null` disables the button (e.g. while [isLoading]).
  final VoidCallback? onTap;
  final Color iconColor;
  final double padding;

  /// Swaps the icon for a small spinner.
  final bool isLoading;

  const _CircularIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
    this.padding = 10,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutralSurface,
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: iconColor,
                  ),
                )
              : Icon(icon, color: iconColor, size: 25),
        ),
      ),
    );
  }
}
