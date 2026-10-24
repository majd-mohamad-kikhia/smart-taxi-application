import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import 'route_point_field_widget.dart';

/// Makes [target] the point being placed on the map. [search] opens its
/// field for typing (the keyboard); without it only the map is in play.
typedef ActivatePoint =
    void Function(PickTarget target, {required bool search});

/// The From / To card at the bottom of the home map: two text fields joined by
/// a dotted connector. They are the place search as well as the points:
///
/// - a field shows its point's address; tapping it makes it the one being
///   placed and opens it for typing, with its text selected so typing
///   replaces it;
/// - typing does not search (that would be a request per letter): the
///   keyboard's search key, or the field's search button, does;
/// - while a point is being placed, its field shows the address under the pin
///   as the map moves, and the places found are chosen from a list above the
///   card.
///
/// The card owns the two text controllers and keeps them in step with the
/// points ([HomeCubit]) and with the pin ([MapPickCubit]); typing itself
/// rebuilds nothing but the field that is typed in.
class RoutePointsCardWidget extends StatefulWidget {
  final ActivatePoint onActivate;

  const RoutePointsCardWidget({super.key, required this.onActivate});

  @override
  State<RoutePointsCardWidget> createState() => _RoutePointsCardWidgetState();
}

class _RoutePointsCardWidgetState extends State<RoutePointsCardWidget> {
  late final HomeCubit _home = context.read<HomeCubit>();
  late final MapPickCubit _pick = context.read<MapPickCubit>();

  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode(debugLabel: 'from');
  final _toFocus = FocusNode(debugLabel: 'to');

  /// The map is flying to a place by itself (a point was opened, a result
  /// chosen), which the cubit reports like a drag. Only a drag by the
  /// customer takes the keyboard away.
  bool _mapIsFlying = false;
  bool _mapWasMoving = false;
  late int _lastMoveCount = _pick.state.moveCount;

  /// The field being placed and the address under the pin, as last shown.
  late PickTarget? _shownTarget = _pick.state.target;
  late String? _shownAddress = _pick.state.address;

  TextEditingController _controller(PickTarget target) =>
      target == PickTarget.from ? _fromController : _toController;

  FocusNode _focus(PickTarget target) =>
      target == PickTarget.from ? _fromFocus : _toFocus;

  String _pointLabel(HomeState state, PickTarget target) =>
      (target == PickTarget.from ? state.fromLocation : state.toLocation)
          ?.displayLabel ??
      '';

  @override
  void initState() {
    super.initState();
    for (final target in PickTarget.values) {
      _controller(target).text = _pointLabel(_home.state, target);
      _focus(target).addListener(() => _selectAllOnFocus(target));
    }
    final picking = _pick.state.target;
    if (picking != null) _controller(picking).text = _pick.state.address ?? '';
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  /// A field that is opened for typing starts with its text selected, so the
  /// first letters replace the address instead of adding to it.
  void _selectAllOnFocus(PickTarget target) {
    final focus = _focus(target);
    if (!focus.hasFocus) return;
    // After the tap that gave the focus has put its cursor down.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !focus.hasFocus) return;
      final controller = _controller(target);
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  void _setText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// The points changed: every field that is not being placed shows its point.
  void _onPointsChanged(HomeState state) {
    final placing = _pick.state.target;
    for (final target in PickTarget.values) {
      if (target != placing) {
        _setText(_controller(target), _pointLabel(state, target));
      }
    }
  }

  /// The pin moved, a place was chosen, or the mode began or ended: the field
  /// being placed shows the address under the pin, the others their points.
  void _onPickChanged(MapPickState state) {
    final placing = state.target;
    // Camera events come through here too; they must not touch what the
    // customer is typing, so the texts follow only a real change of the
    // field being placed or of the address under the pin.
    if (placing != _shownTarget || state.address != _shownAddress) {
      _shownTarget = placing;
      _shownAddress = state.address;
      final home = _home.state;
      for (final target in PickTarget.values) {
        if (target != placing) {
          _setText(_controller(target), _pointLabel(home, target));
        }
      }
      if (placing != null) _setText(_controller(placing), state.address ?? '');
    }

    if (state.moveCount != _lastMoveCount) {
      _lastMoveCount = state.moveCount;
      _mapIsFlying = true;
    }
    final isUserDrag = state.isDragging && !_mapIsFlying;
    // The flight is over when the map settles after having moved.
    if (_mapWasMoving && !state.isDragging) _mapIsFlying = false;
    _mapWasMoving = state.isDragging;
    // The keyboard is in the way of a map being dragged, and of a point that
    // was just placed.
    if (isUserDrag || placing == null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _activate(PickTarget target, {required bool search}) {
    if (_pick.state.target != target) {
      widget.onActivate(target, search: search);
    }
    if (!search) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    // An empty field, tapped: the places picked before are listed.
    if (_controller(target).text.trim().isEmpty) _pick.queryChanged('');
  }

  void _clear(PickTarget target) {
    _controller(target).clear();
    _pick.clearSearch();
    _focus(target).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (previous, current) =>
              previous.fromLocation != current.fromLocation ||
              previous.toLocation != current.toLocation,
          listener: (_, state) => _onPointsChanged(state),
        ),
        BlocListener<MapPickCubit, MapPickState>(
          listenWhen: (previous, current) =>
              previous.target != current.target ||
              previous.address != current.address ||
              previous.isDragging != current.isDragging ||
              previous.moveCount != current.moveCount,
          listener: (_, state) => _onPickChanged(state),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingXS),
        decoration: BoxDecoration(
          color: context.colors.neutralSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BoundFieldWidget(
              target: PickTarget.from,
              controller: _fromController,
              focusNode: _fromFocus,
              onActivate: _activate,
              onClear: _clear,
            ),
            const _ConnectorWidget(),
            _BoundFieldWidget(
              target: PickTarget.to,
              controller: _toController,
              focusNode: _toFocus,
              onActivate: _activate,
              onClear: _clear,
            ),
          ],
        ),
      ),
    );
  }
}

/// What the empty field of the row being placed says.
enum _Hint { placeholder, resolving, unresolved }

/// One row, connected to the state it needs: whether it is being placed,
/// whether it is busy and what it says when empty (from the pin), and whether
/// the points are locked. Only these decide a rebuild.
class _BoundFieldWidget extends StatelessWidget {
  final PickTarget target;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ActivatePoint onActivate;
  final ValueChanged<PickTarget> onClear;

  const _BoundFieldWidget({
    required this.target,
    required this.controller,
    required this.focusNode,
    required this.onActivate,
    required this.onClear,
  });

  ({bool active, bool busy, _Hint hint}) _view(MapPickState state) {
    if (state.target != target) {
      return (active: false, busy: false, hint: _Hint.placeholder);
    }
    final hint = state.address != null || state.addressDeferred
        ? _Hint.placeholder
        : state.isDragging || state.isResolving
        ? _Hint.resolving
        : _Hint.unresolved;
    return (
      active: true,
      busy: state.isSearching || state.isResolving,
      hint: hint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFrom = target == PickTarget.from;
    final pick = context.read<MapPickCubit>();
    final isLocked = context.select<HomeCubit, bool>(
      (cubit) => cubit.state.arePointsLocked,
    );
    final details = context.select<HomeCubit, String?>(
      (cubit) => (isFrom ? cubit.state.fromLocation : cubit.state.toLocation)
          ?.addressDetails,
    );
    return BlocSelector<
      MapPickCubit,
      MapPickState,
      ({bool active, bool busy, _Hint hint})
    >(
      selector: _view,
      builder: (context, view) {
        final placeholder = isFrom
            ? l10n.pickPickupPoint
            : l10n.pickDestination;
        return RoutePointFieldWidget(
          label: isFrom ? l10n.fromLabel : l10n.toLabel,
          marker: isFrom
              ? Icon(
                  Icons.trip_origin_rounded,
                  color: context.colors.primaryContent,
                  size: 20,
                )
              : const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
          controller: controller,
          focusNode: focusNode,
          hint: switch (view.hint) {
            _Hint.placeholder => placeholder,
            _Hint.resolving => l10n.locationResolving,
            _Hint.unresolved => l10n.locationUnresolved,
          },
          details: details,
          isActive: view.active,
          isLocked: isLocked,
          isBusy: view.busy,
          onTap: isLocked ? null : () => onActivate(target, search: true),
          onChanged: view.active ? pick.queryChanged : null,
          onSubmitted: view.active ? pick.submitSearch : null,
          onClear: view.active ? () => onClear(target) : null,
          onPickOnMap: isLocked
              ? null
              : () => onActivate(target, search: false),
        );
      },
    );
  }
}

/// The dotted line between the two markers, with a divider after it.
class _ConnectorWidget extends StatelessWidget {
  const _ConnectorWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: AppConstants.paddingM),
        SizedBox(
          width: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (_) => Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.borderStrong,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(child: Divider(height: 1, color: context.colors.borderLight)),
        const SizedBox(width: AppConstants.paddingS),
      ],
    );
  }
}
