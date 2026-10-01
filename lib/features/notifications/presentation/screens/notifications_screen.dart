import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/paginated_list_widget.dart';
import '../../data/models/notification_model.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_card_widget.dart';
import '../widgets/notifications_header_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        bottom: false,
        // The list itself shows a failed first load; a failed "load more"
        // with rows already on screen surfaces as a snackbar.
        child: BlocListener<NotificationsCubit, NotificationsState>(
          listenWhen: (previous, current) =>
              current.errorMessage != null &&
              current.errorMessage != previous.errorMessage &&
              current.notifications.isNotEmpty,
          listener: (context, state) => showAppSnackBar(
            context,
            state.errorMessage!,
            type: AppSnackBarType.error,
          ),
          child: Column(
            children: [
              NotificationsHeaderWidget(
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, state) =>
                      PaginatedListWidget<NotificationModel>(
                        items: state.notifications,
                        isLoading: state.isLoading,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        errorMessage: state.errorMessage,
                        emptyMessage: context.l10n.notificationsEmpty,
                        emptyIcon: Icons.notifications_off_outlined,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        onLoadMore: cubit.loadMore,
                        onRetry: cubit.initialize,
                        onRefresh: cubit.initialize,
                        itemBuilder: (context, notification, _) =>
                            NotificationCardWidget(notification: notification),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
