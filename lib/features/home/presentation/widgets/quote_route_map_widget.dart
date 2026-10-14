import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_map_style.dart';
import '../../../../core/theme/app_palette.dart';
import '../cubit/quote_route_cubit.dart';
import '../cubit/quote_route_state.dart';

/// A small map for the price sheet: the pickup and drop-off pins and the road
/// route between them, framed to fit. The customer can pan and zoom it to
/// look closer; it claims its touches so that doing so never drags the sheet
/// or scrolls the list behind it, and a button frames the whole route again.
class QuoteRouteMapWidget extends StatefulWidget {
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;

  const QuoteRouteMapWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
  });

  @override
  State<QuoteRouteMapWidget> createState() => _QuoteRouteMapWidgetState();
}

class _QuoteRouteMapWidgetState extends State<QuoteRouteMapWidget>
    with MapStyleMixin {
  static const _framePadding = 56.0;

  GoogleMapController? _controller;

  LatLng get _pickup => LatLng(widget.pickup.latitude, widget.pickup.longitude);
  LatLng get _dropoff =>
      LatLng(widget.dropoff.latitude, widget.dropoff.longitude);

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  /// Frames the route, or just the two pins until it has loaded.
  void _fit(List<RoutePointModel> route) {
    final controller = _controller;
    if (controller == null) return;
    final points = route.length >= 2
        ? [for (final p in route) LatLng(p.lat, p.lng)]
        : [_pickup, _dropoff];
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsOf(points), _framePadding),
    );
  }

  LatLngBounds _boundsOf(List<LatLng> points) {
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  Set<Marker> get _markers => {
    Marker(
      markerId: const MarkerId('pickup'),
      position: _pickup,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('dropoff'),
      position: _dropoff,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ),
  };

  Set<Polyline> _polylines(List<RoutePointModel> route) {
    if (route.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('quote_route'),
        points: [for (final p in route) LatLng(p.lat, p.lng)],
        color: AppColors.mapRoutePlanned,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * 0.24).clamp(
      140.0,
      280.0,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      child: SizedBox(
        height: height,
        child: !mapStyleReady
            ? const SizedBox.shrink()
            : Stack(
                children: [
                  Positioned.fill(child: _map()),
                  PositionedDirectional(
                    top: AppConstants.paddingS,
                    end: AppConstants.paddingS,
                    child: _FitRouteButton(
                      onTap: () =>
                          _fit(context.read<QuoteRouteCubit>().state.points),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _map() {
    return BlocConsumer<QuoteRouteCubit, QuoteRouteState>(
      listenWhen: (previous, current) => previous.points != current.points,
      listener: (context, state) => _fit(state.points),
      buildWhen: (previous, current) => previous.points != current.points,
      builder: (context, state) => GoogleMap(
        style: mapStyle,
        initialCameraPosition: CameraPosition(target: _pickup, zoom: 13),
        markers: _markers,
        polylines: _polylines(state.points),
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        // Claim every touch so panning the map never drags the sheet.
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
        onMapCreated: (controller) {
          _controller = controller;
          _fit(context.read<QuoteRouteCubit>().state.points);
        },
      ),
    );
  }
}

/// Small round button that frames the whole route again after the customer
/// has moved the map.
class _FitRouteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FitRouteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.showWholeRoute,
      child: Material(
        color: colors.backgroundWhite,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingS),
            child: Icon(
              Icons.zoom_out_map_rounded,
              size: 20,
              color: colors.primaryContent,
            ),
          ),
        ),
      ),
    );
  }
}
