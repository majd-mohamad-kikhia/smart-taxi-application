import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_map_style.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/car_heading_tracker.dart';
import '../../../../core/utils/map_framing.dart';
import '../../../../core/utils/taxi_marker_icon.dart';
import '../cubit/driver_home_map_cubit.dart';
import '../cubit/driver_home_map_state.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_orders_state.dart';

/// The driver's home map: where the driver is (a taxi on a soft halo, turned
/// the way the car is going) and, when an offer is being looked at, where it
/// goes — a green pin at the pickup, a red one at the drop-off, and the road
/// between them (a dashed straight line until the road is known).
///
/// With no offer the camera follows the driver. With one, it frames the
/// whole trip. Dragging the map stops the camera following; the round button
/// brings it back. [topInset] and [bottomInset] are the parts of the map
/// covered by the controls on top of it, so what is framed is never hidden
/// behind them.
class DriverHomeMapWidget extends StatefulWidget {
  final double topInset;
  final double bottomInset;

  const DriverHomeMapWidget({
    super.key,
    required this.topInset,
    required this.bottomInset,
  });

  @override
  State<DriverHomeMapWidget> createState() => _DriverHomeMapWidgetState();
}

class _DriverHomeMapWidgetState extends State<DriverHomeMapWidget>
    with MapStyleMixin {
  static const _followZoom = 16.0;
  static const _defaultCenter = LatLng(
    AppConstants.defaultMapLat,
    AppConstants.defaultMapLng,
  );

  GoogleMapController? _controller;
  BitmapDescriptor? _taxiIcon;
  final _heading = CarHeadingTracker();

  /// The camera keeps the driver in view as they move.
  bool _following = true;

  /// A camera move this widget started itself (so it is not the driver
  /// dragging the map).
  bool _movingByCode = false;

  /// The first fix puts the camera on the driver at the follow zoom; the
  /// ones after only slide it.
  bool _hasCentered = false;

  @override
  void initState() {
    super.initState();
    TaxiMarkerIcon.load().then((icon) {
      if (mounted) setState(() => _taxiIcon = icon);
    });
    final state = context.read<DriverHomeMapCubit>().state;
    if (state.hasDriverPosition) {
      _heading.update(LatLng(state.driverLat!, state.driverLng!));
    }
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  LatLng? _driver(DriverHomeMapState state) => state.hasDriverPosition
      ? LatLng(state.driverLat!, state.driverLng!)
      : null;

  Future<void> _move(CameraUpdate update) async {
    final controller = _controller;
    if (controller == null) return;
    _movingByCode = true;
    await controller.animateCamera(update);
  }

  void _followDriver(LatLng driver) {
    _following = true;
    _move(
      _hasCentered
          ? CameraUpdate.newLatLng(driver)
          : CameraUpdate.newLatLngZoom(driver, _followZoom),
    );
    _hasCentered = true;
  }

  void _frameTrip(OrderOfferModel order, DriverHomeMapState state) {
    final points = <LatLng>[
      LatLng(order.pickupLat, order.pickupLng),
      LatLng(order.dropoffLat, order.dropoffLng),
      for (final p in state.orderRoute) LatLng(p.lat, p.lng),
    ];
    _move(CameraUpdate.newLatLngBounds(framingBounds(points), 48));
  }

  /// Puts the camera back where it belongs: on the trip of the offer being
  /// looked at, or else on the driver.
  void _recenter(OrderOfferModel? order, DriverHomeMapState state) {
    setState(() => _following = true);
    final driver = _driver(state);
    if (order != null) {
      _frameTrip(order, state);
    } else if (driver != null) {
      _move(CameraUpdate.newLatLngZoom(driver, _followZoom));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersCubit = sl<DriverOrdersCubit>();
    return MultiBlocListener(
      listeners: [
        // Another offer, or none: frame its trip, or go back to the driver.
        BlocListener<DriverOrdersCubit, DriverOrdersState>(
          bloc: ordersCubit,
          listenWhen: (previous, current) =>
              previous.selectedOrder?.rideId != current.selectedOrder?.rideId,
          listener: (context, ordersState) {
            final mapState = context.read<DriverHomeMapCubit>().state;
            final order = ordersState.selectedOrder;
            if (order != null) {
              _following = true;
              _frameTrip(order, mapState);
            } else {
              final driver = _driver(mapState);
              if (driver != null) _followDriver(driver);
            }
          },
        ),
        BlocListener<DriverHomeMapCubit, DriverHomeMapState>(
          listenWhen: (previous, current) =>
              previous.driverLat != current.driverLat ||
              previous.driverLng != current.driverLng ||
              previous.orderRoute != current.orderRoute,
          listener: (context, mapState) {
            final driver = _driver(mapState);
            if (driver != null) _heading.update(driver);
            final order = ordersCubit.state.selectedOrder;
            if (order != null) {
              // The road arriving widens the frame; the driver moving does not.
              if (_following && mapState.routeRideId == order.rideId) {
                _frameTrip(order, mapState);
              }
            } else if (driver != null && _following) {
              _followDriver(driver);
            }
          },
        ),
      ],
      child: BlocBuilder<DriverHomeMapCubit, DriverHomeMapState>(
        builder: (context, mapState) =>
            BlocBuilder<DriverOrdersCubit, DriverOrdersState>(
              bloc: ordersCubit,
              buildWhen: (previous, current) =>
                  previous.selectedOrder != current.selectedOrder,
              builder: (context, ordersState) {
                final order = ordersState.selectedOrder;
                return Stack(
                  children: [
                    _buildMap(context, mapState, order),
                    if (!_following)
                      PositionedDirectional(
                        end: AppConstants.paddingL,
                        bottom: widget.bottomInset + AppConstants.paddingM,
                        child: _RecenterButton(
                          onTap: () => _recenter(order, mapState),
                        ),
                      ),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    DriverHomeMapState mapState,
    OrderOfferModel? order,
  ) {
    final driver = _driver(mapState);
    final taxi = _taxiIcon;
    final pickup = order == null
        ? null
        : LatLng(order.pickupLat, order.pickupLng);
    final dropoff = order == null
        ? null
        : LatLng(order.dropoffLat, order.dropoffLng);
    final hasRoad =
        order != null &&
        mapState.routeRideId == order.rideId &&
        mapState.orderRoute.length >= 2;

    return GoogleMap(
      style: mapStyle,
      padding: EdgeInsets.only(
        top: widget.topInset,
        bottom: widget.bottomInset,
      ),
      initialCameraPosition: CameraPosition(
        target: driver ?? pickup ?? _defaultCenter,
        zoom: driver == null ? 13 : _followZoom,
      ),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      tiltGesturesEnabled: false,
      onMapCreated: (controller) {
        _controller = controller;
        if (order != null) {
          _frameTrip(order, mapState);
        } else if (driver != null) {
          _followDriver(driver);
        }
      },
      onCameraMoveStarted: () {
        // Only the driver's own drag or pinch stops the following.
        if (!_movingByCode && _following) setState(() => _following = false);
      },
      onCameraIdle: () => _movingByCode = false,
      circles: {
        if (driver != null)
          Circle(
            circleId: const CircleId('driver_halo'),
            center: driver,
            radius: 60,
            fillColor: AppColors.primaryBright.withValues(alpha: 0.18),
            strokeColor: AppColors.primaryBright.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
      },
      polylines: {
        if (hasRoad)
          Polyline(
            polylineId: const PolylineId('offer_road'),
            points: [for (final p in mapState.orderRoute) LatLng(p.lat, p.lng)],
            color: AppColors.mapRoutePlanned,
            width: 6,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          )
        else if (pickup != null && dropoff != null)
          Polyline(
            polylineId: const PolylineId('offer_straight'),
            points: [pickup, dropoff],
            color: AppColors.mapRoutePlanned,
            width: 4,
            patterns: [PatternItem.dash(18), PatternItem.gap(12)],
          ),
      },
      markers: {
        if (driver != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: driver,
            icon:
                taxi ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
            rotation: taxi == null ? 0 : _heading.bearing,
            flat: taxi != null,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 2,
          ),
        if (pickup != null)
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        if (dropoff != null)
          Marker(
            markerId: const MarkerId('dropoff'),
            position: dropoff,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
      },
    );
  }
}

/// The round button that brings the camera back to the driver or the trip
/// after the map was dragged away.
class _RecenterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RecenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.driverMapRecenter,
      child: Material(
        color: colors.backgroundWhite,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              Icons.my_location_rounded,
              color: colors.primaryContent,
            ),
          ),
        ),
      ),
    );
  }
}
