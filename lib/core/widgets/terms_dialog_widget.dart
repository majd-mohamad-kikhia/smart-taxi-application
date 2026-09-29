import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/user_role.dart';
import '../injection/injection.dart';
import '../localization/l10n_context_extension.dart';
import '../terms/terms_cubit.dart';
import '../terms/terms_state.dart';
import '../theme/app_colors.dart';
import 'app_animated_dialog.dart';
import 'app_loader_widget.dart';
import 'auth_primary_button_widget.dart';

/// Opens the terms and conditions for [role]'s app in the shared
/// [showAppDialog] shell, in the language the app is currently using.
/// Shared by the rider sign-up screen and both roles' settings screens.
Future<void> showTermsDialog(BuildContext context, {required UserRole role}) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return showAppDialog<void>(
    context: context,
    title: context.l10n.termsAndConditions,
    icon: Icons.description_rounded,
    showActions: false,
    content: BlocProvider<TermsCubit>(
      create: (_) => sl<TermsCubit>()..load(role, languageCode),
      child: _TermsContentWidget(role: role, languageCode: languageCode),
    ),
  );
}

/// Loading / error / empty / text states rendered inside the dialog shell.
class _TermsContentWidget extends StatelessWidget {
  final UserRole role;
  final String languageCode;

  const _TermsContentWidget({required this.role, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<TermsCubit, TermsState>(
          builder: (context, state) {
            switch (state.status) {
              case TermsLoadStatus.loading:
                return const SizedBox(height: 120, child: AppLoaderWidget(size: 80));
              case TermsLoadStatus.failure:
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? l10n.errServerUnreachable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () =>
                          context.read<TermsCubit>().load(role, languageCode),
                      child: Text(l10n.retry),
                    ),
                  ],
                );
              case TermsLoadStatus.success:
                final terms = state.terms!;
                if (terms.isEmpty) {
                  return Text(
                    l10n.termsEmpty,
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
                      child: Text(
                        terms.content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
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
