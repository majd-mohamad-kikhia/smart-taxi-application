import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../localization/app_locales.dart';
import '../localization/l10n_context_extension.dart';
import '../localization/locale_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import 'app_snack_bar_widget.dart';

/// Settings card with a dropdown to switch the app language. Shared by the
/// customer and driver settings screens; the choice is saved on the server
/// and persisted by [LocaleCubit] — and only takes effect (text and layout
/// direction, app-wide) once the server accepted it.
class LanguageDropdownWidget extends StatelessWidget {
  const LanguageDropdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.translate_rounded,
              size: 20,
              color: context.colors.primaryContent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.language,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _LanguagePicker(),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatefulWidget {
  const _LanguagePicker();

  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  bool _isSaving = false;

  Future<void> _select(Locale locale) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    final error = await context.read<LocaleCubit>().changeLanguage(locale);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      showAppSnackBarOn(messenger, error, type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LocaleCubit, Locale, Locale>(
      selector: (locale) => locale,
      builder: (context, current) {
        return PopupMenuButton<Locale>(
          tooltip: context.l10n.language,
          initialValue: current,
          offset: const Offset(0, 46),
          color: context.colors.backgroundWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: context.colors.border),
          ),
          enabled: !_isSaving,
          onSelected: _select,
          itemBuilder: (_) => [
            for (final locale in AppLocales.supported)
              PopupMenuItem<Locale>(
                value: locale,
                child: _LanguageOption(
                  locale: locale,
                  isSelected: locale == current,
                ),
              ),
          ],
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: context.colors.backgroundMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocales.nativeName(current),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                if (_isSaving)
                  Padding(
                    padding: EdgeInsets.all(2),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.primaryContent,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: context.colors.primaryContent,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final Locale locale;
  final bool isSelected;

  const _LanguageOption({required this.locale, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : context.colors.backgroundMuted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            locale.languageCode.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? AppColors.textOnPrimary
                  : context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          AppLocales.nativeName(locale),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? context.colors.primaryContent : context.colors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.check_rounded,
          size: 18,
          color: isSelected ? context.colors.primaryContent : AppColors.transparent,
        ),
      ],
    );
  }
}
