import 'package:flutter/material.dart';
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
    final itemCount = widget.items.length + (widget.isLoadingMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => widget.separator,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textOnPrimary),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.retry,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
