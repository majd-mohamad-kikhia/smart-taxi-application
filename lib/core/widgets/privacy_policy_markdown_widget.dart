import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../theme/app_colors.dart';

/// Renders the privacy policy's Markdown in the app's dark palette.
class PrivacyPolicyMarkdownWidget extends StatelessWidget {
  final String content;

  const PrivacyPolicyMarkdownWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const body = TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary);
    const heading = TextStyle(
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: AppColors.textPrimary,
    );

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: body,
        listBullet: body,
        strong: body.copyWith(fontWeight: FontWeight.w700),
        h1: heading.copyWith(fontSize: 20),
        h2: heading.copyWith(fontSize: 17, color: AppColors.primary),
        h3: heading.copyWith(fontSize: 15),
        h1Padding: const EdgeInsets.only(bottom: 4),
        h2Padding: const EdgeInsets.only(top: 12),
        h3Padding: const EdgeInsets.only(top: 8),
        blockquote: body.copyWith(fontSize: 13),
        blockquotePadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        tableHead: body.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
        tableBody: body.copyWith(fontSize: 13),
        tableColumnWidth: const FixedColumnWidth(150),
        tableCellsPadding: const EdgeInsets.all(8),
        tableBorder: TableBorder.all(color: AppColors.border),
      ),
    );
  }
}
