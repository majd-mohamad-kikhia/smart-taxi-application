import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/delete_account_button_widget.dart';
import '../../data/models/driver_deletion_request_model.dart';
import '../cubit/driver_account_deletion_cubit.dart';
import '../cubit/driver_account_deletion_state.dart';
import 'driver_delete_account_dialog_widget.dart';
import 'driver_deletion_status_card_widget.dart';

/// The driver settings' account-deletion block. Shows the "delete account"
/// button, or — per the latest request's status — "under review" with a
/// cancel action, or "declined" with the manager's note and the button again.
class DriverAccountDeletionSectionWidget extends StatelessWidget {
  const DriverAccountDeletionSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverAccountDeletionCubit>(
      create: (_) => sl<DriverAccountDeletionCubit>()..load(),
      child: const _DeletionSectionView(),
    );
  }
}

class _DeletionSectionView extends StatelessWidget {
  const _DeletionSectionView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriverAccountDeletionCubit>();
    return BlocConsumer<DriverAccountDeletionCubit, DriverAccountDeletionState>(
      listenWhen: (previous, current) =>
          current.actionError != null &&
          current.actionError != previous.actionError,
      listener: (context, state) => showAppSnackBar(
        context,
        state.actionError!,
        type: AppSnackBarType.error,
      ),
      builder: (context, state) {
        final l10n = context.l10n;
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        }
        if (state.loadError != null) {
          return Column(
            children: [
              Text(
                state.loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              TextButton(onPressed: cubit.load, child: Text(l10n.retry)),
            ],
          );
        }

        final request = state.request;
        final deleteButton = DeleteAccountButtonWidget(
          onPressed: () => showDriverDeleteAccountDialog(context, cubit: cubit),
        );
        return switch (request?.status) {
          DriverDeletionStatus.pending => DriverDeletionStatusCardWidget(
            icon: Icons.hourglass_top_rounded,
            title: l10n.driverDeletionPendingTitle,
            body: l10n.driverDeletionPendingBody,
            actionLabel: l10n.driverDeletionCancel,
            isActionLoading: state.isCancelling,
            onAction: cubit.cancel,
          ),
          DriverDeletionStatus.rejected => Column(
            children: [
              DriverDeletionStatusCardWidget(
                icon: Icons.cancel_outlined,
                title: l10n.driverDeletionRejectedTitle,
                body: request!.reviewNote,
                isError: true,
              ),
              const SizedBox(height: 8),
              deleteButton,
            ],
          ),
          _ => deleteButton,
        };
      },
    );
  }
}
