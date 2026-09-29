import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Modal collecting a required cancellation reason — shared by the
/// customer ride-tracking screen and the driver trip screen. Pops with
/// the trimmed reason string on confirm, or `null` on dismiss/back out.
class CancelReasonDialogWidget extends StatefulWidget {
  /// Defaults to the localized "Cancel trip" / reason prompt.
  final String? title;
  final String? message;

  const CancelReasonDialogWidget({super.key, this.title, this.message});

  @override
  State<CancelReasonDialogWidget> createState() => _CancelReasonDialogWidgetState();
}

class _CancelReasonDialogWidgetState extends State<CancelReasonDialogWidget> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = context.l10n.cancelReasonRequired);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.error, size: 36),
            const SizedBox(height: 12),
            Text(
              widget.title ?? l10n.cancelTrip,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              widget.message ?? l10n.cancelTripReasonPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 255,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.cancelReasonHint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                errorText: _error,
                filled: true,
                fillColor: AppColors.backgroundMuted,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.goBack),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    child: Text(l10n.confirmCancellation),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
