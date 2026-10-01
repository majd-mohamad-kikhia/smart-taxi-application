import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../localization/app_locales.dart';
import '../localization/l10n_context_extension.dart';
import '../localization/locale_cubit.dart';
import '../theme/app_colors.dart';

/// A compact one-tap language switch for the screens before sign-in, so
/// someone who reads English can change the language without first having
/// to sign in and find it in Settings.
///
/// It shows the language it will switch *to*, written in that language
/// ("English" while the app is Arabic, "العربية" while it is English), so it
/// stays readable whichever language is on screen. With more than two
/// languages it steps to the next one in [AppLocales.supported]. With no
/// signed-in account the change is local; the current language is sent to
/// the server when the person signs in.
class AuthLanguageToggleWidget extends StatelessWidget {
  const AuthLanguageToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, current) {
        final locales = AppLocales.supported;
        final next = locales[(locales.indexOf(current) + 1) % locales.length];
        return Tooltip(
          message: context.l10n.language,
          child: TextButton.icon(
            onPressed: () => context.read<LocaleCubit>().changeLanguage(next),
            icon: const Icon(Icons.translate_rounded, size: 18),
            label: Text(AppLocales.nativeName(next)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textLink,
              minimumSize: const Size(48, 48),
            ),
          ),
        );
      },
    );
  }
}
