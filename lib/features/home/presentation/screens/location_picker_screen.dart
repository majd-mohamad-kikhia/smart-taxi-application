import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../../../core/theme/app_map_style.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/geo/geo_exception.dart';
import '../../data/pin_label_resolver.dart';
import '../../data/repositories/places_repository.dart';
import '../widgets/address_details_field_widget.dart';
import '../widgets/place_search_field_widget.dart';
import '../widgets/place_search_message_widget.dart';

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

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with MapStyleMixin {
  static const _defaultCenter = LatLng(
    AppConstants.defaultMapLat,
    AppConstants.defaultMapLng,
  );
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
  String? _pickedAddress;

  /// A reverse-geocode for the current pin is in flight.
  bool _isResolvingAddress = false;

  /// The place last chosen from the search list. It already is a name, so it
  /// stands in while the pin stays on that spot.
  ({double lat, double lng, String address})? _selectedAnchor;
  bool _isLocating = false;

  /// Confirming is only allowed once the pin has a real, resolved address
  /// — never a bare coordinate pair, and never a stale address left over
  /// from a previous pin position.
  bool get _canConfirm => _pickedAddress != null && !_isResolvingAddress;

  /// The point being edited came with an `alias_id`.
  ({int aliasId, double lat, double lng})? _initialAlias;

  /// The query last submitted: an answer for any other is out of date.
  String _submittedQuery = '';

  /// The point the server resolved a search to, until the pin is confirmed.
  ({int aliasId, double lat, double lng})? _resolved;
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
    if (initial?.aliasId != null) {
      _initialAlias = (
        aliasId: initial!.aliasId!,
        lat: initial.latitude,
        lng: initial.longitude,
      );
    }
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
    sl<PlacesRepository>().cancelSearch();
    _searchController.dispose();
    _detailsController.dispose();
    // Drop the reference so no late async callback can reach a controller
    // whose GoogleMap widget is gone.
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundGray,
      body: Stack(
        children: [
          GoogleMap(
            style: mapStyle,
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
              setState(() => _searchError = null);
            },
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on_rounded,
                  color: widget.isPickup
                      ? context.colors.primaryContent
                      : context.colors.accentContent,
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
                            color: context.colors.neutralSurface,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusFull,
                            ),
                          ),
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
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
                          onSubmitted: _submitSearch,
                          onClear: _clearSearch,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingM),
                      _CircularIconButton(
                        icon: Icons.my_location_rounded,
                        iconColor: context.colors.primaryContent,
                        padding: 13,
                        isLoading: _isLocating,
                        onTap: _isLocating ? null : _useCurrentLocation,
                      ),
                    ],
                  ),
                  if (_searchError != null) ...[
                    const SizedBox(height: AppConstants.paddingS),
                    PlaceSearchMessageWidget(message: _searchError!),
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
                  color: context.colors.neutralSurface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  border: Border.all(color: context.colors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pin_drop_rounded,
                          color: context.colors.textSecondary,
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
                                  ? context.colors.textPrimary
                                  : context.colors.textSecondary,
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
        aliasId: _confirmedAliasId(),
      ),
    );
  }

  /// What the order carries as the point's `alias_id`: the resolved place's
  /// when the confirmed pin stayed on it (the server also hears whether it
  /// did), otherwise that of the point being edited if the pin is still there.
  int? _confirmedAliasId() {
    final resolved = _resolved;
    _resolved = null;
    if (resolved != null) {
      final stayed = sl<PlacesRepository>().reportConfirmed(
        aliasId: resolved.aliasId,
        resolvedLatitude: resolved.lat,
        resolvedLongitude: resolved.lng,
        pinLatitude: _center.latitude,
        pinLongitude: _center.longitude,
      );
      return stayed ? resolved.aliasId : null;
    }
    final initial = _initialAlias;
    if (initial == null) return null;
    final meters = PinLabelResolver.distanceMeters(
      initial.lat,
      initial.lng,
      _center.latitude,
      _center.longitude,
    );
    return meters <= PlacesRepository.acceptedMeters ? initial.aliasId : null;
  }

  /// The text changed. Nothing is searched or sent while typing: only the
  /// keyboard's search key (or the search icon) does, through
  /// [_submitSearch]. Emptying the box drops a search still on its way.
  void _onSearchChanged(String value) {
    if (_searchError != null) setState(() => _searchError = null);
    if (value.trim().isEmpty) {
      sl<PlacesRepository>().cancelSearch();
      setState(() => _isSearching = false);
    }
  }

  /// The customer submitted the text (the keyboard's search key, or the
  /// search icon): the server turns it into a point.
  Future<void> _submitSearch(String value) async {
    if (!PlacesRepository.isSearchable(value)) {
      sl<PlacesRepository>().cancelSearch();
      setState(() {
        _isSearching = false;
        _searchError = context.l10n.searchMinChars;
      });
      return;
    }
    final query = PlacesRepository.normalizeQuery(value);
    if (query == _submittedQuery && _isSearching) return;
    _submittedQuery = query;
    await _resolve(() => sl<PlacesRepository>().submit(value), value);
  }

  void _clearSearch() {
    sl<PlacesRepository>().cancelSearch();
    _submittedQuery = '';
    _searchController.clear();
    setState(() {
      _searchError = null;
      _isSearching = false;
    });
  }

  /// Runs [ask] and shows what it came to: a point (the pin moves there), a
  /// "did you mean …?", or nothing found (the customer places the pin).
  Future<void> _resolve(
    Future<PlaceOutcome> Function() ask,
    String query,
  ) async {
    sl<PlacesRepository>().cancelSearch();
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final outcome = await ask();
      if (!mounted) return;
      switch (outcome) {
        case PlaceFound():
          _showFound(outcome);
        case PlaceDidYouMean():
          setState(() => _isSearching = false);
          await _askDidYouMean(outcome, query);
        case PlaceNotFound():
          setState(() {
            _isSearching = false;
            _searchError = context.l10n.placesNotFoundMovePin;
          });
      }
    } on GeoException {
      // Replaced by a newer search, which reports for itself.
    }
  }

  void _showFound(PlaceFound found) {
    final target = LatLng(found.latitude, found.longitude);
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(target, 17));
    _resolved = (
      aliasId: found.aliasId,
      lat: found.latitude,
      lng: found.longitude,
    );
    setState(() {
      _selectedAnchor = (
        lat: found.latitude,
        lng: found.longitude,
        address: found.label,
      );
      _center = target;
      _pickedAddress = found.label;
      _isSearching = false;
      _searchController.text = found.label;
    });
    final corrected = found.correctedTo;
    if (corrected != null) {
      showAppSnackBar(context, context.l10n.placeCorrectedTo(corrected));
    }
  }

  Future<void> _askDidYouMean(PlaceDidYouMean suggestion, String query) async {
    final l10n = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.didYouMeanTitle),
        content: Text(l10n.didYouMeanMessage(suggestion.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.answerNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.answerYes),
          ),
        ],
      ),
    );
    if (!mounted || yes == null) return;
    await _resolve(
      () => sl<PlacesRepository>().submit(
        query,
        aliasId: yes ? suggestion.aliasId : null,
        forceGoogle: !yes,
      ),
      query,
    );
  }

  Future<void> _reverseGeocodeCenter() async {
    final target = _center;
    // The pin is still on the place the customer chose: its own name is the
    // right one — a lookup would name the street under it instead.
    final chosen = _selectedSuggestionAddressAt(target);
    if (chosen != null) {
      setState(() {
        _pickedAddress = chosen;
        _isResolvingAddress = false;
      });
      return;
    }
    setState(() {
      _pickedAddress = null;
      _isResolvingAddress = true;
    });
    final address = await sl<PlacesRepository>().addressFor(
      target.latitude,
      target.longitude,
      reason: 'picker pin',
    );
    // The pin moved on while this lookup ran; the newer lookup owns the
    // state now.
    if (!mounted || _center != target) return;
    setState(() {
      _pickedAddress = address;
      _isResolvingAddress = false;
    });
  }

  /// The chosen place's name, if the pin is still on that place (within a few
  /// meters — the camera may settle a hair off).
  String? _selectedSuggestionAddressAt(LatLng target) {
    final anchor = _selectedAnchor;
    if (anchor == null) return null;
    const tolerance = 0.0001;
    final isSamePlace =
        (anchor.lat - target.latitude).abs() < tolerance &&
        (anchor.lng - target.longitude).abs() < tolerance;
    return isSamePlace ? anchor.address : null;
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

  /// Defaults to the theme's primary text color.
  final Color? iconColor;
  final double padding;

  /// Swaps the icon for a small spinner.
  final bool isLoading;

  const _CircularIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.padding = 10,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.neutralSurface,
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
                    color: iconColor ?? context.colors.textPrimary,
                  ),
                )
              : Icon(
                  icon,
                  color: iconColor ?? context.colors.textPrimary,
                  size: 25,
                ),
        ),
      ),
    );
  }
}
