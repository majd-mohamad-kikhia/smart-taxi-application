import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../cubit/driver_ratings_cubit.dart';
import '../cubit/driver_ratings_state.dart';
import '../widgets/rating_tile_widget.dart';
import '../widgets/ratings_summary_widget.dart';

/// "My ratings": the average and the bars per star, then every rating a
/// customer gave this driver, newest first.
class DriverRatingsScreen extends StatelessWidget {
  const DriverRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverRatingsCubit>(
      create: (_) => sl<DriverRatingsCubit>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray,
        appBar: AppBar(title: Text(context.l10n.myRatingsTitle)),
        body: const _RatingsBody(),
      ),
    );
  }
}

class _RatingsBody extends StatelessWidget {
  const _RatingsBody();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriverRatingsCubit>();
    return BlocBuilder<DriverRatingsCubit, DriverRatingsState>(
      builder: (context, state) {
        if (state.isLoading) return const AppLoaderWidget();
        if (!state.isLoaded) {
          return _Message(
            text: state.errorMessage ?? context.l10n.errServerUnreachable,
            actionLabel: context.l10n.retry,
            onAction: cubit.load,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 300) cubit.loadMore();
                  return false;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppConstants.paddingL),
                  children: [
                    RatingsSummaryWidget(summary: state.summary),
                    const SizedBox(height: AppConstants.paddingL),
                    if (state.ratings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingXL),
                        child: Text(
                          context.l10n.noRatingsYet,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final rating in state.ratings) ...[
                      RatingTileWidget(rating: rating),
                      const SizedBox(height: AppConstants.paddingM),
                    ],
                    if (state.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(AppConstants.paddingL),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                      ),
                    if (state.errorMessage != null && state.ratings.isNotEmpty)
                      _Message(
                        text: state.errorMessage!,
                        actionLabel: context.l10n.retry,
                        onAction: cubit.loadMore,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({required this.text, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
