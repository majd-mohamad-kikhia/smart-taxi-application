import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
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
            prev.fieldErrors != curr.fieldErrors ||
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
  /// The API's names for the fields the form can show an error under.
  static const _fieldKeys = {
    'first_name',
    'last_name',
    'phone_number',
    'email',
    'address',
  };

  final _formKey = GlobalKey<EditProfileFormWidgetState>();
  bool _isDirty = false;

  /// Leaving with unsaved edits asks first.
  Future<void> _confirmDiscard() {
    final l10n = context.l10n;
    return showAppDialog<void>(
      context: context,
      title: l10n.discardChangesTitle,
      message: l10n.discardChangesMessage,
      icon: Icons.edit_off_rounded,
      tone: AppDialogTone.warning,
      confirmLabel: l10n.discardChangesConfirm,
      cancelLabel: l10n.keepEditing,
      onConfirm: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isSaving = state.status == EditProfileStatus.saving;
    // A problem with one field shows under that field; the banner keeps the
    // general message and anything the form has no field for.
    final bannerLines = [
      if (state.errorMessage != null &&
          !state.fieldErrors.values.contains(state.errorMessage))
        state.errorMessage!,
      for (final entry in state.fieldErrors.entries)
        if (!_fieldKeys.contains(entry.key)) entry.value,
    ];

    return PopScope(
      canPop: !_isDirty || isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingXL),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: EditProfileFormWidget(
              key: _formKey,
              profile: widget.profile,
              isSaving: isSaving,
              serverErrors: state.fieldErrors,
              onDirtyChanged: (dirty) => setState(() => _isDirty = dirty),
              banner: bannerLines.isEmpty
                  ? null
                  : AuthErrorBannerWidget(message: bannerLines.join('\n')),
              // Save works only while there is something to save.
              submitButton: AuthPrimaryButtonWidget(
                label: context.l10n.saveChanges,
                isLoading: isSaving,
                onPressed: _isDirty
                    ? () => _formKey.currentState?.submit()
                    : null,
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
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
