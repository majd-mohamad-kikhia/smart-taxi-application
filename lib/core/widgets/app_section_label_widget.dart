import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';

/// The small heading above a group of content ("Pickup spot", "Recent
/// destinations"): a bold, quiet label. It is announced as a heading.
///
/// No letter spacing or forced capitals: the label is often Arabic, where
/// spacing breaks the joined letters.
class AppSectionLabelWidget extends StatelessWidget {
  final String label;

  const AppSectionLabelWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppConstants.paddingXS,
        bottom: AppConstants.paddingS,
      ),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.colors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
