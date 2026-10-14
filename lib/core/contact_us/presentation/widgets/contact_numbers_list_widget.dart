import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_constants.dart';
import '../../../injection/injection.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_palette.dart';
import '../../data/models/contact_number_model.dart';
import '../cubit/contact_us_cubit.dart';
import '../cubit/contact_us_state.dart';
import 'contact_number_tile_widget.dart';

/// The manager's contact numbers for [app] under a short heading — tap to
/// call or open WhatsApp. Shows nothing while loading, when there are none,
/// or when they can't be loaded: it is an extra, never a reason for an
/// error on the screen it sits in.
///
/// With [onlyType] only numbers reached that way are listed (for example
/// WhatsApp only), and [showHeading] false drops the "Call our call center"
/// line for a caller that already says what the numbers are for.
class ContactNumbersListWidget extends StatelessWidget {
  final ContactUsApp app;
  final ContactType? onlyType;
  final bool showHeading;

  const ContactNumbersListWidget({
    super.key,
    required this.app,
    this.onlyType,
    this.showHeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return BlocProvider<ContactUsCubit>(
      create: (_) =>
          sl<ContactUsCubit>(instanceName: app.wireValue)..load(lang: lang),
      child: BlocBuilder<ContactUsCubit, ContactUsState>(
        builder: (context, state) {
          if (state is! ContactUsLoaded) return const SizedBox.shrink();
          final numbers = [
            for (final number in state.numbers)
              if (onlyType == null || number.type == onlyType) number,
          ];
          if (numbers.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeading) ...[
                const SizedBox(height: AppConstants.paddingL),
                Text(
                  context.l10n.contactCallCenter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
              ],
              for (final number in numbers) ...[
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
