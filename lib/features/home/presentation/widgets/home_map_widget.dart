import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/picked_location_model.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import 'map_center_marker_widget.dart';

/// The live map that fills the home screen. It moves to the customer when
/// [HomeState.locateCount] changes and to a searched place when
/// [MapPickState.moveCount] does, reports where its camera is to the
/// [MapPickCubit], and carries a fixed marker at its center.
class HomeMapWidget extends StatefulWidget {
  const HomeMapWidget({super.key});

  @override
  State<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends State<HomeMapWidget> {
  static const _defaultCenter = LatLng(
    AppConstants.defaultMapLat,
    AppConstants.defaultMapLng,
  );

  GoogleMapController? _controller;
  String? _mapStyle;

  /// A move that was asked for before the map was created.
  ({LatLng target, double zoom})? _pendingMove;
  late LatLng _initialTarget;

  /// Where the camera is looking, as of the last move.
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    final known = context.read<HomeCubit>().state.userLocation;
    _initialTarget = known == null
        ? _defaultCenter
        : LatLng(known.latitude, known.longitude);
    _center = _initialTarget;
    // Entering pick mode before the camera ever moves still knows the pin.
    context.read<MapPickCubit>().onCameraMove(
      _initialTarget.latitude,
      _initialTarget.longitude,
    );
    _loadMapStyle();
  }

  @override
  void dispose() {
    // Drop the reference so no late callback can reach a controller whose
    // GoogleMap widget is gone.
    _controller = null;
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString(
      'assets/map_styles/dark_map_style.json',
    );
    if (mounted) setState(() => _mapStyle = style);
  }

  void _moveTo(PickedLocationModel? location, double zoom) {
    if (location == null) return;
    final target = LatLng(location.latitude, location.longitude);
    final controller = _controller;
    if (controller == null) {
      _pendingMove = (target: target, zoom: zoom);
      return;
    }
    controller.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  @override
  Widget build(BuildContext context) {
    final pick = context.read<MapPickCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (previous, current) =>
              previous.locateCount != current.locateCount,
          listener: (context, state) => _moveTo(state.userLocation, 16),
        ),
        BlocListener<MapPickCubit, MapPickState>(
          listenWhen: (previous, current) =>
              previous.moveCount != current.moveCount,
          listener: (context, state) => _moveTo(state.moveTarget, state.moveZoom),
        ),
      ],
      child: Stack(
        children: [
          GoogleMap(
            style: _mapStyle,
            initialCameraPosition: CameraPosition(
              target: _initialTarget,
              zoom: 15,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _controller = controller;
              final pending = _pendingMove;
              if (pending != null) {
                _pendingMove = null;
                controller.moveCamera(
                  CameraUpdate.newLatLngZoom(pending.target, pending.zoom),
                );
              }
            },
            onCameraMove: (position) {
              _center = position.target;
              pick.onCameraMove(_center.latitude, _center.longitude);
            },
            onCameraIdle: () =>
                pick.onCameraIdle(_center.latitude, _center.longitude),
            onTap: (_) {
              FocusScope.of(context).unfocus();
              pick.dismissSuggestions();
            },
          ),
          const IgnorePointer(child: MapCenterMarkerWidget()),
        ],
      ),
    );
  }
}
