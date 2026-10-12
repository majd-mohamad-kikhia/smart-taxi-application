import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Renders the privacy policy's Markdown in the active theme's palette.
class PrivacyPolicyMarkdownWidget extends StatelessWidget {
  final String content;

  const PrivacyPolicyMarkdownWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = TextStyle(fontSize: 14, height: 1.6, color: context.colors.textPrimary);
    final heading = TextStyle(
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: context.colors.textPrimary,
    );

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: body,
        listBullet: body,
        strong: body.copyWith(fontWeight: FontWeight.w700),
        h1: heading.copyWith(fontSize: 20),
        h2: heading.copyWith(fontSize: 17, color: context.colors.primaryContent),
        h3: heading.copyWith(fontSize: 15),
        h1Padding: const EdgeInsets.only(bottom: 4),
        h2Padding: const EdgeInsets.only(top: 12),
        h3Padding: const EdgeInsets.only(top: 8),
        blockquote: body.copyWith(fontSize: 13),
        blockquotePadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          color: context.colors.warningSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        tableHead: body.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
        tableBody: body.copyWith(fontSize: 13),
        tableColumnWidth: const FixedColumnWidth(150),
        tableCellsPadding: const EdgeInsets.all(8),
        tableBorder: TableBorder.all(color: context.colors.border),
      ),
    );
  }
}
