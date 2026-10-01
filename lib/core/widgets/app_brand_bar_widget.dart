import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_constants.dart';
import '../injection/injection.dart';
import '../localization/l10n_context_extension.dart';
import '../notifications/unread_notifications_cubit.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import 'app_logo_widget.dart';

/// Shared brand top bar — the Mshoar logo and app name at the start edge —
/// used as the app bar for both the customer and driver apps so the two look
/// alike. `showNotifications` is the only difference between them: the
/// customer bar shows the bell (end edge), the driver bar doesn't.
///
/// Lives in `core/widgets` (not `features/home`) because both
/// `features/home` and `driver_features` render it — per the project's
/// "shared across features → core" rule.
class AppBrandBarWidget extends StatelessWidget {
  final bool showNotifications;

  const AppBrandBarWidget({super.key, this.showNotifications = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundWhite,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          // The brand mark sits at the start edge: right in Arabic (RTL),
          // left in English (LTR).
          const Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _BrandLogoWidget(),
            ),
          ),
          if (showNotifications) const _NotificationBellWidget(),
        ],
      ),
    );
  }
}

class _BrandLogoWidget extends StatelessWidget {
  const _BrandLogoWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base =
        theme.appBarTheme.titleTextStyle ?? theme.textTheme.headlineSmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppLogoWidget(size: 40),
        const SizedBox(width: 10),
        // The wordmark: the app bar title style (brand yellow), larger and
        // heavier. A line height of 1 with the extra leading split evenly
        // puts the letters on the logo's vertical center instead of sitting
        // low in a taller line box.
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            context.l10n.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
      ],
    );
  }
}

/// Notification bell — customer only. A 48dp target around a 44dp tile,
/// named for screen readers, with a count badge when there is something
/// unread (a number as well as a color, so it never relies on color alone).
class _NotificationBellWidget extends StatefulWidget {
  const _NotificationBellWidget();

  @override
  State<_NotificationBellWidget> createState() =>
      _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<_NotificationBellWidget> {
  UnreadNotificationsCubit get _unread => sl<UnreadNotificationsCubit>();

  @override
  void initState() {
    super.initState();
    _unread.refresh();
  }

  Future<void> _open() async {
    await Navigator.of(context).pushNamed(AppRouter.notifications);
    // Reading happens on that screen; ask again in case more came in.
    _unread.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<UnreadNotificationsCubit, int>(
      bloc: _unread,
      builder: (context, unread) {
        final label = unread > 0
            ? l10n.notificationsUnreadLabel(unread)
            : l10n.notificationsTitle;
        return Tooltip(
          message: label,
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: Material(
              color: AppColors.transparent,
              child: InkResponse(
                onTap: _open,
                radius: 28,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                      if (unread > 0)
                        PositionedDirectional(
                          top: 0,
                          end: 0,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusFull,
                              ),
                              border: Border.all(
                                color: AppColors.backgroundWhite,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textOnPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
