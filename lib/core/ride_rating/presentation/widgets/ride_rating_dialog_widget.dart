import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_palette.dart';
import '../../../widgets/app_animated_dialog.dart';
import '../../../widgets/app_choice_chip_widget.dart';
import '../../../widgets/app_neutral_button_widget.dart';
import '../../../widgets/app_surface_card_widget.dart';
import '../../../widgets/auth_error_banner_widget.dart';
import '../../../widgets/auth_primary_button_widget.dart';
import '../../../widgets/network_photo_widget.dart';
import '../../data/models/ride_rating_model.dart';
import '../cubit/ride_rating_cubit.dart';
import '../cubit/ride_rating_state.dart';
import 'star_rating_widget.dart';

/// How the rating dialog ended, when it was not skipped.
class RideRatingOutcome {
  /// The rating the server stored; null when the trip turned out to be rated
  /// already (the caller should reload it to show the real stars).
  final RideRatingModel? rating;

  const RideRatingOutcome({this.rating});

  bool get alreadyRated => rating == null;
}

/// Who drove, for the card at the top of the rating dialog. Display only.
class RideRatingDriverInfo {
  final String name;
  final String? photoUrl;

  /// The car as one line ("Kia Rio • White").
  final String? vehicle;

  const RideRatingDriverInfo({required this.name, this.photoUrl, this.vehicle});
}

/// Asks the customer to rate the driver of a completed trip: five stars,
/// quick compliments, an optional comment, Send and Skip. Resolves with a
/// [RideRatingOutcome], or null when the customer skipped (nothing is sent).
///
/// [justFinished] is for the moment the trip ends: the dialog then opens as
/// "Trip completed!" with a thank-you line. [driver] adds the driver's card
/// and names them in the question.
Future<RideRatingOutcome?> showRideRatingDialog(
  BuildContext context, {
  required RideRatingCubit Function() createCubit,
  RideRatingDriverInfo? driver,
  bool justFinished = false,
}) {
  final l10n = context.l10n;
  return showAppDialog<RideRatingOutcome>(
    context: context,
    eyebrow: justFinished ? l10n.tripArrivedSafely : null,
    title: justFinished ? l10n.tripCompletedTitle : l10n.rateDriverTitle,
    message: justFinished ? l10n.tripCompletedThanks : null,
    icon: justFinished ? Icons.check_rounded : Icons.star_rounded,
    tone: AppDialogTone.primary,
    showActions: false,
    // Closing it mid-send would hide the result; Skip is the way out.
    barrierDismissible: false,
    content: BlocProvider<RideRatingCubit>(
      create: (_) => createCubit(),
      child: _RatingFormWidget(driver: driver),
    ),
  );
}

class _RatingFormWidget extends StatefulWidget {
  final RideRatingDriverInfo? driver;

  const _RatingFormWidget({required this.driver});

  @override
  State<_RatingFormWidget> createState() => _RatingFormWidgetState();
}

class _RatingFormWidgetState extends State<_RatingFormWidget> {
  static const int _maxCommentLength = 500;
  static final RegExp _separator = RegExp(r'\s*[,،]\s*');

  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  List<String> get _commentParts => _commentController.text
      .split(_separator)
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  /// A compliment chip adds its words to the comment, or takes them out
  /// again: the comment field stays the one thing that is sent.
  void _toggleCompliment(String phrase, String separator) {
    final parts = _commentParts;
    if (!parts.remove(phrase)) parts.add(phrase);
    final text = parts.join(separator);
    if (text.length > _maxCommentLength) return;
    _commentController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    return BlocConsumer<RideRatingCubit, RideRatingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == RideRatingStatus.sent) {
          Navigator.of(context).pop(RideRatingOutcome(rating: state.saved));
        } else if (state.status == RideRatingStatus.alreadyRated) {
          Navigator.of(context).pop(const RideRatingOutcome());
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final textTheme = Theme.of(context).textTheme;
        final cubit = context.read<RideRatingCubit>();
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final compliments = [
          l10n.complimentSmoothDriving,
          l10n.complimentCleanCar,
          l10n.complimentPolite,
          l10n.complimentOnTime,
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSurfaceCardWidget(
              color: context.colors.backgroundMuted,
              bordered: false,
              child: Column(
                children: [
                  if (driver != null) ...[
                    _DriverHeader(driver: driver),
                    const SizedBox(height: AppConstants.paddingM),
                  ],
                  Text(
                    driver != null
                        ? l10n.rateRideWith(driver.name)
                        : l10n.rateDriverMessage,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  StarRatingWidget(
                    value: state.stars.toDouble(),
                    size: 42,
                    showFaces: true,
                    onChanged: state.isSending ? null : cubit.selectStars,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              driver != null
                  ? l10n.rateComplimentTitle(driver.name)
                  : l10n.rateCommentLabel,
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppConstants.paddingS),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _commentController,
              builder: (context, _, _) {
                final chosen = _commentParts;
                return Wrap(
                  spacing: AppConstants.paddingS,
                  runSpacing: AppConstants.paddingXS,
                  children: [
                    for (final phrase in compliments)
                      AppChoiceChipWidget(
                        label: phrase,
                        selected: chosen.contains(phrase),
                        onSelected: state.isSending
                            ? null
                            : (_) => _toggleCompliment(
                                phrase,
                                isRtl ? '، ' : ', ',
                              ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppConstants.paddingM),
            TextField(
              controller: _commentController,
              enabled: !state.isSending,
              maxLength: _maxCommentLength,
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.rateCommentLabel,
                hintText: l10n.rateCommentHint,
                alignLabelWithHint: true,
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppConstants.paddingS),
              AuthErrorBannerWidget(message: state.errorMessage!),
            ],
            const SizedBox(height: AppConstants.paddingM),
            AuthPrimaryButtonWidget(
              label: l10n.rateSend,
              isLoading: state.isSending,
              onPressed: state.canSend
                  ? () => cubit.send(_commentController.text)
                  : null,
            ),
            const SizedBox(height: AppConstants.paddingM),
            AppNeutralButtonWidget(
              label: l10n.rateSkip,
              onPressed: state.isSending ? null : () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

/// The driver at the top of the rating card: photo in a green ring, name in
/// bold, the car under it.
class _DriverHeader extends StatelessWidget {
  final RideRatingDriverInfo driver;

  const _DriverHeader({required this.driver});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final vehicle = driver.vehicle;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.primarySurface,
          ),
          child: NetworkPhotoWidget(
            imagePath: driver.photoUrl,
            width: 64,
            height: 64,
            borderRadius: 32,
            placeholderIcon: Icons.person_rounded,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        Text(
          driver.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (vehicle != null && vehicle.isNotEmpty)
          Text(
            vehicle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// The stars a customer gave, with their comment, for a trip's details.
class RideRatingSummaryWidget extends StatelessWidget {
  final RideRatingModel rating;

  const RideRatingSummaryWidget({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourRating,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppConstants.paddingS),
        StarRatingWidget(value: rating.value.toDouble(), size: 24),
        if (rating.comment != null) ...[
          const SizedBox(height: AppConstants.paddingS),
          Text(
            rating.comment!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
