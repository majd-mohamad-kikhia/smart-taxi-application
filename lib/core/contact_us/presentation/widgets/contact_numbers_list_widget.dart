import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_constants.dart';
import '../../../injection/injection.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../data/models/contact_number_model.dart';
import '../cubit/contact_us_cubit.dart';
import '../cubit/contact_us_state.dart';
import 'contact_number_tile_widget.dart';

/// The manager's contact numbers for [app] under a short heading — tap to
/// call or open WhatsApp. Shows nothing while loading, when there are none,
/// or when they can't be loaded: it is an extra, never a reason for an
/// error on the screen it sits in.
class ContactNumbersListWidget extends StatelessWidget {
  final ContactUsApp app;

  const ContactNumbersListWidget({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return BlocProvider<ContactUsCubit>(
      create: (_) =>
          sl<ContactUsCubit>(instanceName: app.wireValue)..load(lang: lang),
      child: BlocBuilder<ContactUsCubit, ContactUsState>(
        builder: (context, state) {
          if (state is! ContactUsLoaded || state.numbers.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.paddingL),
              Text(
                context.l10n.contactCallCenter,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingS),
              for (final number in state.numbers) ...[
                ContactNumberTileWidget(number: number),
                const SizedBox(height: AppConstants.paddingS),
              ],
            ],
          );
        },
      ),
    );
  }
}
