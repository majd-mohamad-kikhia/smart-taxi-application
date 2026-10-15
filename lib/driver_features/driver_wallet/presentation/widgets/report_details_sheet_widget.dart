import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_sheet_handle_widget.dart';

/// Opens a bottom sheet with a [title] and the [children] under it, for the
/// details of one row of a wallet report list. Scrolls when the content is
/// taller than the screen.
Future<void> showReportDetailsSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.neutralSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _ReportDetailsSheet(title: title, children: children),
  );
}

class _ReportDetailsSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ReportDetailsSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHandleWidget(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingXL,
              AppConstants.paddingS,
              AppConstants.paddingXL,
              AppConstants.paddingXL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingL),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
