import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_logo_widget.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/app_sheet_handle_widget.dart';
import '../../../../core/widgets/entrance_animation_widget.dart';
import '../../../../core/widgets/vehicle_type_icon_widget.dart';
import '../../../../core/widgets/vehicle_type_photo_widget.dart';
import '../../data/models/vehicle_type_quote_model.dart';

/// Opens the "about this car" sheet for [vehicleType] over the price sheet.
Future<void> showVehicleTypeInfoSheet(
  BuildContext context,
  VehicleTypeQuoteModel vehicleType,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.neutralSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => VehicleTypeInfoSheetWidget(vehicleType: vehicleType),
  );
}

/// What a car type is about: its picture (or its icon), its name, the line the manager wrote
/// for it (its description, in full — a price card cuts it to one line) in a
/// soft quote card, and the brand's slogan with the logo at the foot. A type
/// with no description shows just the name and the slogan.
class VehicleTypeInfoSheetWidget extends StatelessWidget {
  final VehicleTypeQuoteModel vehicleType;

  const VehicleTypeInfoSheetWidget({super.key, required this.vehicleType});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final description = vehicleType.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

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
              AppConstants.paddingL,
              AppConstants.paddingXL,
              AppConstants.paddingXL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The icon rises in first, then the words.
                EntranceAnimationWidget(
                  from: const Offset(0, 12),
                  fromScale: 0.85,
                  child: vehicleType.imageUrl == null
                      ? Center(child: _IconBadge(name: vehicleType.name))
                      : VehicleTypePhotoWidget(
                          name: vehicleType.name,
                          imageUrl: vehicleType.imageUrl,
                          width: double.infinity,
                          height: 180,
                          borderRadius: AppConstants.radiusLarge,
                          iconSize: 72,
                          background: context.colors.primarySurface,
                        ),
                ),
                const SizedBox(height: AppConstants.paddingL),
                EntranceAnimationWidget(
                  index: 1,
                  from: const Offset(0, 12),
                  child: Semantics(
                    header: true,
                    child: Text(
                      vehicleType.name,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (hasDescription) ...[
                  const SizedBox(height: AppConstants.paddingL),
                  EntranceAnimationWidget(
                    index: 2,
                    from: const Offset(0, 12),
                    child: _QuoteCard(text: description),
                  ),
                ],
                const SizedBox(height: AppConstants.paddingXL),
                EntranceAnimationWidget(
                  index: 3,
                  from: const Offset(0, 12),
                  child: const _BrandSlogan(),
                ),
                const SizedBox(height: AppConstants.paddingXL),
                AppNeutralButtonWidget(
                  label: l10n.gotIt,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The car's icon in a round badge, inside a ring of the brand's wash.
class _IconBadge extends StatelessWidget {
  final String name;

  const _IconBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 104,
        height: 104,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primarySurface,
          shape: BoxShape.circle,
        ),
        child: VehicleTypeIconWidget(name: name, size: 72),
      ),
    );
  }
}

/// The car's description in a tinted card with a quote mark, set larger and
/// looser than body text so a short tagline reads as a tagline.
class _QuoteCard extends StatelessWidget {
  final String text;

  const _QuoteCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primarySurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.format_quote_rounded,
                size: 32,
                color: colors.primaryContent,
              ),
            ),
            const SizedBox(height: AppConstants.paddingXS),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The logo with the brand's slogan beside it. The slogan is the same in
/// every language, so it always reads left to right.
class _BrandSlogan extends StatelessWidget {
  const _BrandSlogan();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const ExcludeSemantics(child: AppLogoWidget(size: 32)),
        const SizedBox(width: AppConstants.paddingM),
        Flexible(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              AppConstants.appSlogan,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
