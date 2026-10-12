import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// "Cancel route": a pill in the middle of the map's left edge that clears
/// the From and To points. Shown only while a point is set and nothing holds
/// the points (a quote, booking or live ride).
class CancelRouteButtonWidget extends StatelessWidget {
  const CancelRouteButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, bool>(
      selector: (state) =>
          !state.arePointsLocked &&
          (state.fromLocation != null || state.toLocation != null),
      builder: (context, visible) {
        if (!visible) return const SizedBox.shrink();
        final label = context.l10n.cancelRoute;
        return Container(
          decoration: BoxDecoration(
            color: context.colors.neutralSurface,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(AppConstants.radiusFull),
            ),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppColors.transparent,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(AppConstants.radiusFull),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: context.read<HomeCubit>().resetPoints,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppConstants.paddingM,
                  end: AppConstants.paddingL,
                  top: AppConstants.paddingS,
                  bottom: AppConstants.paddingS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
