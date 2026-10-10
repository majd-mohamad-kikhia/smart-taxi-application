import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_animated_dialog.dart';
import '../../../widgets/app_neutral_button_widget.dart';
import '../../../widgets/auth_error_banner_widget.dart';
import '../../../widgets/auth_primary_button_widget.dart';
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

/// Asks the customer to rate the driver of a completed trip: five stars, an
/// optional comment, Send and Skip. Resolves with a [RideRatingOutcome], or
/// null when the customer skipped (nothing is sent).
Future<RideRatingOutcome?> showRideRatingDialog(
  BuildContext context, {
  required RideRatingCubit Function() createCubit,
}) {
  final l10n = context.l10n;
  return showAppDialog<RideRatingOutcome>(
    context: context,
    title: l10n.rateDriverTitle,
    message: l10n.rateDriverMessage,
    icon: Icons.star_rounded,
    tone: AppDialogTone.warning,
    showActions: false,
    // Closing it mid-send would hide the result; Skip is the way out.
    barrierDismissible: false,
    content: BlocProvider<RideRatingCubit>(
      create: (_) => createCubit(),
      child: const _RatingFormWidget(),
    ),
  );
}

class _RatingFormWidget extends StatefulWidget {
  const _RatingFormWidget();

  @override
  State<_RatingFormWidget> createState() => _RatingFormWidgetState();
}

class _RatingFormWidgetState extends State<_RatingFormWidget> {
  static const int _maxCommentLength = 500;

  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        final cubit = context.read<RideRatingCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: StarRatingWidget(
                value: state.stars.toDouble(),
                size: 38,
                showFaces: true,
                onChanged: state.isSending ? null : cubit.selectStars,
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
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
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
