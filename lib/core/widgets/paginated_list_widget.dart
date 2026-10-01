import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';
import 'app_loader_widget.dart';

/// Generic infinite-scroll list used everywhere the app shows a server-
/// paginated collection (wallet history, ride history, admin lists, ...).
/// Owns loading, error, empty and load-more states so a screen only has
/// to supply data and an [itemBuilder] — never re-implements this shell.
///
/// [items] is the full accumulated list loaded so far (not just the
/// current page). As the user scrolls near the bottom, [onLoadMore] is
/// called to fetch and append the next page.
class PaginatedListWidget<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final String? errorMessage;
  final VoidCallback? onRetry;
  /// Defaults to the localized "No data" text.
  final String? emptyMessage;
  final IconData emptyIcon;
  final EdgeInsetsGeometry padding;
  final Widget separator;

  /// Pull-to-refresh handler. Omit it on screens with nothing to
  /// re-fetch (e.g. locally-cached data with no backing "get" endpoint)
  /// — when null, no [RefreshIndicator] is shown.
  final Future<void> Function()? onRefresh;

  const PaginatedListWidget({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 8),
    this.separator = const SizedBox(height: 10),
    this.onRefresh,
  });

  @override
  State<PaginatedListWidget<T>> createState() => _PaginatedListWidgetState<T>();
}

class _PaginatedListWidgetState<T> extends State<PaginatedListWidget<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore || widget.onLoadMore == null) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      widget.onLoadMore!();
    }
  }

  /// Scroll position only changes once content overflows the viewport —
  /// with a small page size (or a small first page), the loaded items can
  /// fit on screen with nothing to scroll, so [_onScroll] never fires even
  /// though more pages exist. Called after every layout to keep fetching
  /// until either the list overflows or there's no more data.
  void _loadMoreIfContentFitsViewport() {
    if (!mounted || !widget.hasMore || widget.isLoadingMore || widget.onLoadMore == null) {
      return;
    }
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfContentFitsViewport());
    Widget body = _buildBody();
    if (widget.onRefresh != null) {
      body = RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.backgroundWhite,
        onRefresh: widget.onRefresh!,
        child: body,
      );
    }
    return body;
  }

  Widget _buildBody() {
    if (widget.isLoading && widget.items.isEmpty) {
      return _fillWithScroll(const AppLoaderWidget());
    }
    if (widget.errorMessage != null && widget.items.isEmpty) {
      return _fillWithScroll(
        _ErrorState(message: widget.errorMessage!, onRetry: widget.onRetry),
      );
    }
    if (widget.items.isEmpty) {
      return _fillWithScroll(
        _EmptyState(
          message: widget.emptyMessage ?? context.l10n.noData,
          icon: widget.emptyIcon,
        ),
      );
    }
    // With rows on screen, a failed request shows as a footer under the
    // last row (instead of silently doing nothing) so the user can retry.
    final hasFooterError = widget.errorMessage != null && !widget.isLoadingMore;
    final itemCount =
        widget.items.length + (widget.isLoadingMore || hasFooterError ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => widget.separator,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return widget.isLoadingMore
              ? const _LoadMoreSpinner()
              : _LoadMoreError(onRetry: widget.onLoadMore ?? widget.onRetry);
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }

  /// Wraps a non-list state (loading/error/empty) in a scrollable that
  /// fills the available height, so [RefreshIndicator]'s drag gesture
  /// still works even when there's no list content to scroll.
  Widget _fillWithScroll(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

/// The spinner row under the last item while the next page loads.
class _LoadMoreSpinner extends StatelessWidget {
  const _LoadMoreSpinner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingL),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.primary,
            semanticsLabel: context.l10n.loading,
          ),
        ),
      ),
    );
  }
}

/// The footer shown under the last item when loading more failed, with a
/// retry that is a real button (48dp, ripple, screen-reader role).
class _LoadMoreError extends StatelessWidget {
  final VoidCallback? onRetry;

  const _LoadMoreError({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppConstants.paddingS,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.textSecondary),
          Text(l10n.loadMoreFailed, style: Theme.of(context).textTheme.bodyMedium),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Shared layout of the full-area states (error and empty): a round icon
/// tile, a centered message and an optional action.
class _StateView extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _StateView({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppConstants.paddingL),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateView(
      icon: Icons.error_outline_rounded,
      message: message,
      action: onRetry == null
          ? null
          : ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.retry),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) => _StateView(icon: icon, message: message);
}
