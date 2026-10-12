import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_palette.dart';
import '../theme/theme_cubit.dart';

/// Settings card with a Light / Dark switch for the app theme. Shared by the
/// customer and driver settings screens; the choice applies at once and is
/// saved on the device by [ThemeCubit].
class ThemeSwitchWidget extends StatelessWidget {
  const ThemeSwitchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              Icons.brightness_6_rounded,
              size: 20,
              color: context.colors.primaryContent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.appearance,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_rounded, size: 18),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_rounded, size: 18),
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  context.read<ThemeCubit>().setMode(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}
