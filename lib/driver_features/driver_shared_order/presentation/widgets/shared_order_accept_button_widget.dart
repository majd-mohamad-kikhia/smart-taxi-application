import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';

/// The order screen's bottom bar: "Accept order", with a spinner while the
/// accept is in flight (taps are ignored then).
class SharedOrderAcceptButtonWidget extends StatelessWidget {
  final bool isAccepting;
  final VoidCallback onAccept;

  const SharedOrderAcceptButtonWidget({
    super.key,
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: AuthPrimaryButtonWidget(
            label: context.l10n.sharedOrderAccept,
            isLoading: isAccepting,
            onPressed: isAccepting ? null : onAccept,
          ),
        ),
      ),
    );
  }
}
