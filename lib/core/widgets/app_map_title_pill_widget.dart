import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';
import 'app_logo_widget.dart';

/// The title of a full-screen map ("Track trip") as a white pill floating at
/// the top: the app's logo tile and the title in bold. It stands in for an
/// app bar where the map runs to the top edge. Announced as a heading.
class AppMapTitlePillWidget extends StatelessWidget {
  final String title;

  const AppMapTitlePillWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
      decoration: BoxDecoration(
        color: colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(child: AppLogoWidget(size: 30)),
          const SizedBox(width: AppConstants.paddingS),
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
