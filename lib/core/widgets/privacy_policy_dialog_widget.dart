import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../injection/injection.dart';
import '../localization/l10n_context_extension.dart';
import '../privacy_policy/privacy_policy_cubit.dart';
import '../privacy_policy/privacy_policy_state.dart';
import '../theme/app_colors.dart';
import 'app_animated_dialog.dart';
import 'app_loader_widget.dart';
import 'auth_primary_button_widget.dart';
import 'privacy_policy_markdown_widget.dart';

/// Opens the privacy policy in the shared [showAppDialog] shell, in the
/// language the app is currently using. Shared by the customer sign-up screen
/// and both roles' settings screens.
Future<void> showPrivacyPolicyDialog(BuildContext context) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return showAppDialog<void>(
    context: context,
    title: context.l10n.privacyPolicy,
    icon: Icons.privacy_tip_rounded,
    showActions: false,
    content: BlocProvider<PrivacyPolicyCubit>(
      create: (_) => sl<PrivacyPolicyCubit>()..load(languageCode),
      child: _PrivacyPolicyContentWidget(languageCode: languageCode),
    ),
  );
}

/// Loading / error / empty / text states rendered inside the dialog shell.
class _PrivacyPolicyContentWidget extends StatelessWidget {
  final String languageCode;

  const _PrivacyPolicyContentWidget({required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<PrivacyPolicyCubit, PrivacyPolicyState>(
          builder: (context, state) {
            switch (state.status) {
              case PrivacyPolicyLoadStatus.loading:
                return const SizedBox(height: 120, child: AppLoaderWidget());
              case PrivacyPolicyLoadStatus.failure:
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? l10n.errServerUnreachable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.errorText),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () =>
                          context.read<PrivacyPolicyCubit>().load(languageCode),
                      child: Text(l10n.retry),
                    ),
                  ],
                );
              case PrivacyPolicyLoadStatus.success:
                final policy = state.policy!;
                if (policy.isEmpty) {
                  return Text(
                    l10n.privacyPolicyEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: PrivacyPolicyMarkdownWidget(content: policy.content),
                    ),
                  ),
                );
            }
          },
        ),
        const SizedBox(height: 16),
        AuthPrimaryButtonWidget(
          label: l10n.close,
          isLoading: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
