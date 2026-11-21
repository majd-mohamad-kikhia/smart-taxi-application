import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../cubit/driver_presence_cubit.dart';
import '../cubit/driver_presence_state.dart';
import 'driver_online_toggle_widget.dart';

/// The driver's online/offline control as a floating button over the map,
/// with nothing but the one next action: a green "Go online" while offline,
/// a white "Go offline" while online or connecting (the status itself is
/// said by the note at the top of the screen). Going offline with offers on
/// screen asks first, like [DriverOnlineToggleWidget].
class DriverOnlineFabWidget extends StatelessWidget {
  const DriverOnlineFabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DriverPresenceCubit, DriverPresenceState, bool>(
      bloc: sl<DriverPresenceCubit>(),
      selector: (state) =>
          state.status == DriverPresenceStatus.online ||
          state.status == DriverPresenceStatus.connecting,
      builder: (context, isWorking) {
        final l10n = context.l10n;
        final cubit = sl<DriverPresenceCubit>();
        return FloatingActionButton.extended(
          // Only one on screen, and the tab pages must not share a hero.
          heroTag: null,
          onPressed: isWorking
              ? () => confirmDriverGoOffline(context, cubit)
              : cubit.goOnline,
          backgroundColor: isWorking
              ? context.colors.backgroundWhite
              : AppColors.primary,
          foregroundColor: isWorking
              ? context.colors.textPrimary
              : AppColors.textOnPrimary,
          icon: Icon(
            isWorking ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: isWorking ? AppColors.error : AppColors.textOnPrimary,
          ),
          label: Text(
            isWorking ? l10n.presenceGoOffline : l10n.presenceGoOnline,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      },
    );
  }
}
