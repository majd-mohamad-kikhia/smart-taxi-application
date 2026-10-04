import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../account_block/account_block_cubit.dart';
import '../account_block/account_block_state.dart';
import '../constants/app_constants.dart';
import '../injection/injection.dart';
import '../l10n/generated/app_localizations.dart';
import '../localization/l10n_context_extension.dart';
import '../models/account_block_model.dart';
import 'app_animated_dialog.dart';
import 'app_choice_chip_widget.dart';
import 'app_destructive_button_widget.dart';
import 'app_dialog_layout_widget.dart';
import 'app_neutral_button_widget.dart';
import 'auth_error_banner_widget.dart';
import 'warning_notice_widget.dart';

/// The preset reasons offered when cancelling a trip, worded to fit both
/// the customer and the driver.
enum _CancelReason {
  waitingTooLong,
  wrongLocation,
  cannotReach,
  plansChanged,
  other;

  String label(AppLocalizations l10n) => switch (this) {
        waitingTooLong => l10n.cancelReasonWaitingTooLong,
        wrongLocation => l10n.cancelReasonWrongLocation,
        cannotReach => l10n.cancelReasonCannotReach,
        plansChanged => l10n.cancelReasonPlansChanged,
        other => l10n.cancelReasonOther,
      };
}

/// Modal collecting a cancellation reason — shared by the customer
/// ride-tracking screen and the driver trip screen. The user picks a preset
/// reason and may add a note ("Other" requires one). Pops with the reason
/// string on confirm, or `null` on dismiss/back out.
///
/// When the account has a cancellation limit, the dialog also shows how
/// many cancellations are used, since too many can block the account —
/// unless [warning] replaces that notice, or [showCancelLimit] is false
/// because this cancel can't count.
class CancelReasonDialogWidget extends StatefulWidget {
  /// Defaults to the localized "Cancel trip" / reason prompt.
  final String? title;
  final String? message;
  final String? warning;
  final bool showCancelLimit;

  const CancelReasonDialogWidget({
    super.key,
    this.title,
    this.message,
    this.warning,
    this.showCancelLimit = true,
  });

  @override
  State<CancelReasonDialogWidget> createState() => _CancelReasonDialogWidgetState();
}

class _CancelReasonDialogWidgetState extends State<CancelReasonDialogWidget> {
  final TextEditingController _noteController = TextEditingController();
  _CancelReason? _selected;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _select(_CancelReason reason) {
    setState(() {
      _selected = reason;
      _error = null;
    });
  }

  void _submit() {
    final l10n = context.l10n;
    final selected = _selected;
    final note = _noteController.text.trim();

    if (selected == null) {
      setState(() => _error = l10n.cancelReasonPick);
      return;
    }
    if (selected == _CancelReason.other && note.isEmpty) {
      setState(() => _error = l10n.cancelReasonRequired);
      return;
    }

    final label = selected.label(l10n);
    Navigator.of(context).pop(
      selected == _CancelReason.other
          ? note
          : (note.isEmpty ? label : '$label — $note'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialogLayoutWidget(
      child: AppAnimatedDialog(
        title: widget.title ?? l10n.cancelTrip,
        message: widget.message ?? l10n.cancelTripReasonChoosePrompt,
        cancelLabel: l10n.goBack,
        icon: Icons.cancel_rounded,
        tone: AppDialogTone.destructive,
        showActions: false,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.warning != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.paddingL),
                child: WarningNoticeWidget(message: widget.warning!),
              )
            else if (widget.showCancelLimit)
              const _CancelLimitNoticeWidget(),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppConstants.paddingS,
              runSpacing: AppConstants.paddingS,
              children: [
                for (final reason in _CancelReason.values)
                  AppChoiceChipWidget(
                    label: reason.label(l10n),
                    selected: _selected == reason,
                    onSelected: (_) => _select(reason),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingL),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: _selected == _CancelReason.other
                    ? l10n.cancelReasonNoteRequiredHint
                    : l10n.cancelReasonNoteHint,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConstants.paddingM),
              AuthErrorBannerWidget(message: _error!),
            ],
            const SizedBox(height: AppConstants.paddingL),
            AppDestructiveButtonWidget(
              label: l10n.confirmCancellation,
              isLoading: false,
              onPressed: _submit,
            ),
            const SizedBox(height: AppConstants.paddingS),
            SizedBox(
              width: double.infinity,
              child: AppNeutralButtonWidget(
                label: l10n.goBack,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Cancelling too often can block your account" plus the running count,
/// shown only when the server reported a cancellation limit for the account.
class _CancelLimitNoticeWidget extends StatelessWidget {
  const _CancelLimitNoticeWidget();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AccountBlockCubit, AccountBlockState, AccountBlockModel>(
      bloc: sl<AccountBlockCubit>(),
      selector: (state) => state.block,
      builder: (context, block) {
        if (block.strikeLimit <= 0) return const SizedBox.shrink();
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.paddingL),
          child: WarningNoticeWidget(
            message: '${l10n.cancelLimitWarning}\n'
                '${l10n.accountBlockedStrikes(block.cancelStrikes, block.strikeLimit)}',
          ),
        );
      },
    );
  }
}
