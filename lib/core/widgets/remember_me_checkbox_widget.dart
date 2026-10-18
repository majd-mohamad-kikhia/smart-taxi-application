import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_palette.dart';

/// The "Remember me" choice under a sign-in form: a checkbox, its label and
/// a line saying what it keeps. The whole row is the tap target, and it reads
/// as one checkbox to a screen reader.
class RememberMeCheckboxWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const RememberMeCheckboxWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    return Semantics(
      container: true,
      checked: value,
      enabled: onChanged != null,
      label: '${l10n.rememberMe}. ${l10n.rememberMeHint}',
      excludeSemantics: true,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (v) => onChanged!(v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.paddingS,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.rememberMe,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.rememberMeHint,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
