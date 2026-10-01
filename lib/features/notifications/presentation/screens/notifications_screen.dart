import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/paginated_list_widget.dart';
import '../../data/models/notification_model.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_card_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsCubit>(
      create: (_) => sl<NotificationsCubit>()..initialize(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  /// Marks it read, and opens the trip when it is about one.
  void _open(BuildContext context, NotificationModel notification) {
    context.read<NotificationsCubit>().markRead(notification.id);
    final rideId = notification.relatedRideId;
    if (rideId != null) {
      Navigator.of(context).pushNamed(AppRouter.rideDetails, arguments: rideId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          BlocSelector<NotificationsCubit, NotificationsState, int>(
            selector: (state) => state.unreadCount,
            builder: (context, unread) => unread == 0
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: cubit.markAllRead,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textLink,
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(l10n.notificationsMarkAllRead),
                  ),
          ),
        ],
      ),
      // The list itself shows a failed first load; a failed "load more" or
      // "mark as read" with rows already on screen surfaces as a snackbar.
      body: BlocListener<NotificationsCubit, NotificationsState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage &&
            current.notifications.isNotEmpty,
        listener: (context, state) => showAppSnackBar(
          context,
          state.errorMessage!,
          type: AppSnackBarType.error,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) =>
                  PaginatedListWidget<NotificationModel>(
                    items: state.notifications,
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    hasMore: state.hasMore,
                    errorMessage: state.errorMessage,
                    emptyMessage: l10n.notificationsEmpty,
                    emptyIcon: Icons.notifications_off_outlined,
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.paddingL,
                      AppConstants.paddingL,
                      AppConstants.paddingL,
                      AppConstants.paddingXXL,
                    ),
                    onLoadMore: cubit.loadMore,
                    onRetry: cubit.initialize,
                    onRefresh: cubit.initialize,
                    itemBuilder: (context, notification, _) =>
                        NotificationCardWidget(
                          notification: notification,
                          onTap: () => _open(context, notification),
                        ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
