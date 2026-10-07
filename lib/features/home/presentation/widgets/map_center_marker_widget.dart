import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';

/// What sits at the center of the home map: a quiet dot normally, and while a
/// point is being placed a pin (yellow for pickup, orange for destination)
/// with the address under it in a small bubble.
class MapCenterMarkerWidget extends StatelessWidget {
  const MapCenterMarkerWidget({super.key});

  static const _pinSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapPickCubit, MapPickState>(
      buildWhen: (previous, current) =>
          previous.target != current.target ||
          previous.address != current.address,
      builder: (context, state) {
        final target = state.target;
        if (target == null) return const Center(child: _DotWidget());
        final color = target == PickTarget.from
            ? AppColors.primary
            : AppColors.accent;
        final bubbleWidth = MediaQuery.sizeOf(context).width * 0.7;
        // A zero-size anchor at the map's center: the pin's tip sits on it
        // and the bubble floats above the pin, so the bubble appearing never
        // shifts the pin off the spot it marks.
        return Center(
          child: SizedBox.shrink(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: 0,
                  left: -_pinSize / 2,
                  width: _pinSize,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: color,
                    size: _pinSize,
                  ),
                ),
                if (state.address != null)
                  Positioned(
                    bottom: _pinSize + AppConstants.paddingXS,
                    left: -bubbleWidth / 2,
                    width: bubbleWidth,
                    child: Center(
                      child: _AddressBubbleWidget(address: state.address!),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddressBubbleWidget extends StatelessWidget {
  final String address;

  const _AddressBubbleWidget({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DotWidget extends StatelessWidget {
  const _DotWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.2),
      ),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(color: AppColors.neutralPage, width: 2.5),
        ),
      ),
    );
  }
}
