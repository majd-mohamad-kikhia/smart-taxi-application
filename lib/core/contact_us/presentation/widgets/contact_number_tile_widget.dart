import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/open_external_url.dart';
import '../../../widgets/app_snack_bar_widget.dart';
import '../../data/models/contact_number_model.dart';

/// One "Contact us" number. Tapping it opens [ContactNumberModel.url] as is
/// (`tel:` → dialer, `wa.me` → WhatsApp) and says so when nothing can open it.
class ContactNumberTileWidget extends StatelessWidget {
  final ContactNumberModel number;

  const ContactNumberTileWidget({super.key, required this.number});

  bool get _isWhatsApp => number.type == ContactType.whatsapp;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = _isWhatsApp
        ? context.l10n.whatsappNotAvailable
        : context.l10n.callNotAvailable;
    final opened = await openExternalUrl(number.url);
    if (!opened) {
      showAppSnackBarOn(messenger, failure, type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _isWhatsApp ? AppColors.success : AppColors.primary;
    final surface = _isWhatsApp
        ? AppColors.successSurface
        : AppColors.primarySurface;
    final radius = BorderRadius.circular(AppConstants.radiusMedium);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingS),
                  child: Icon(
                    _isWhatsApp ? Icons.chat_rounded : Icons.call_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Numbers read left-to-right even in the Arabic UI.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        number.phoneNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.paddingS),
              Icon(
                _isWhatsApp ? Icons.chat_outlined : Icons.call_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
