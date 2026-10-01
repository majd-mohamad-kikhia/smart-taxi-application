import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../data/models/customer_profile_model.dart';
import '../cubit/edit_profile_cubit.dart';
import '../cubit/edit_profile_state.dart';
import '../widgets/edit_profile_form_widget.dart';

/// Lets the customer edit their personal info (`PUT /api/customer/profile`).
/// Pops with `true` once a save succeeds.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditProfileCubit>(
      create: (_) => sl<EditProfileCubit>()..load(),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatelessWidget {
  const _EditProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: Text(context.l10n.editPersonalInfo)),
      body: BlocConsumer<EditProfileCubit, EditProfileState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status == EditProfileStatus.saved,
        listener: (context, state) {
          showAppSnackBar(
            context,
            context.l10n.profileSaved,
            type: AppSnackBarType.success,
          );
          Navigator.of(context).pop(true);
        },
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.errorMessage != curr.errorMessage ||
            prev.profile != curr.profile,
        builder: (context, state) {
          final profile = state.profile;
          if (profile == null) {
            return state.status == EditProfileStatus.failure
                ? _LoadError(
                    message: state.errorMessage ?? context.l10n.errLoadData,
                    onRetry: context.read<EditProfileCubit>().load,
                  )
                : const Center(child: AppLoaderWidget());
          }
          return _EditProfileBody(state: state, profile: profile);
        },
      ),
    );
  }
}

class _EditProfileBody extends StatefulWidget {
  final EditProfileState state;
  final CustomerProfileModel profile;

  const _EditProfileBody({required this.state, required this.profile});

  @override
  State<_EditProfileBody> createState() => _EditProfileBodyState();
}

class _EditProfileBodyState extends State<_EditProfileBody> {
  final _formKey = GlobalKey<EditProfileFormWidgetState>();

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isSaving = state.status == EditProfileStatus.saving;
    final details = [
      if (state.errorMessage != null) state.errorMessage!,
      ...state.fieldErrors.values,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: EditProfileFormWidget(
            key: _formKey,
            profile: widget.profile,
            banner: details.isEmpty
                ? null
                : AuthErrorBannerWidget(message: details.join('\n')),
            submitButton: AuthPrimaryButtonWidget(
              label: context.l10n.saveChanges,
              isLoading: isSaving,
              onPressed: () => _formKey.currentState?.submit(),
            ),
            onSubmit:
                ({
                  required firstName,
                  required lastName,
                  required phone,
                  required email,
                  required address,
                }) => context.read<EditProfileCubit>().save(
                  firstName: firstName,
                  lastName: lastName,
                  phone: phone,
                  email: email,
                  address: address,
                ),
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
