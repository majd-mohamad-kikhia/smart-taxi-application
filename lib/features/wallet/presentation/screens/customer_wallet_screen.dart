import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/paginated_list_widget.dart';
import '../../data/models/customer_wallet_transaction_model.dart';
import '../cubit/customer_wallet_cubit.dart';
import '../cubit/customer_wallet_state.dart';
import '../widgets/customer_wallet_balance_widget.dart';
import '../widgets/customer_wallet_transaction_row_widget.dart';

/// The customer's wallet tab: the balance on top and the history under it,
/// newest first. Pull down to reload; [refreshSignal] reloads it too, when
/// the shell bumps it as the tab is opened.
class CustomerWalletScreen extends StatelessWidget {
  final ValueListenable<int> refreshSignal;

  const CustomerWalletScreen({super.key, required this.refreshSignal});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomerWalletCubit>(
      create: (_) => sl<CustomerWalletCubit>()..initialize(),
      child: _CustomerWalletView(refreshSignal: refreshSignal),
    );
  }
}

class _CustomerWalletView extends StatefulWidget {
  final ValueListenable<int> refreshSignal;

  const _CustomerWalletView({required this.refreshSignal});

  @override
  State<_CustomerWalletView> createState() => _CustomerWalletViewState();
}

class _CustomerWalletViewState extends State<_CustomerWalletView> {
  @override
  void initState() {
    super.initState();
    widget.refreshSignal.addListener(_onRefreshSignal);
  }

  @override
  void didUpdateWidget(_CustomerWalletView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal.removeListener(_onRefreshSignal);
      widget.refreshSignal.addListener(_onRefreshSignal);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal.removeListener(_onRefreshSignal);
    super.dispose();
  }

  void _onRefreshSignal() => context.read<CustomerWalletCubit>().refresh();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerWalletCubit>();
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.colors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(showNotifications: true),
      ),
      // The list shows a failed first load itself; a failed "load more" or
      // pull-to-refresh with rows already on screen surfaces as a snackbar.
      body: MultiBlocListener(
        listeners: [
          BlocListener<CustomerWalletCubit, CustomerWalletState>(
            listenWhen: (previous, current) =>
                current.errorMessage != null &&
                current.errorMessage != previous.errorMessage &&
                current.transactions.isNotEmpty,
            listener: (context, state) => showAppSnackBar(
              context,
              state.errorMessage!,
              type: AppSnackBarType.error,
            ),
          ),
          BlocListener<CustomerWalletCubit, CustomerWalletState>(
            listenWhen: (previous, current) =>
                current.refreshErrorMessage != null &&
                current.refreshErrorMessage != previous.refreshErrorMessage,
            listener: (context, state) => showAppSnackBar(
              context,
              state.refreshErrorMessage!,
              type: AppSnackBarType.error,
            ),
          ),
        ],
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: BlocBuilder<CustomerWalletCubit, CustomerWalletState>(
              builder: (context, state) {
                final balance = state.balance;
                return Column(
                  children: [
                    if (balance != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppConstants.paddingL,
                          AppConstants.paddingS,
                          AppConstants.paddingL,
                          0,
                        ),
                        child: CustomerWalletBalanceWidget(balance: balance),
                      ),
                    Expanded(
                      child: PaginatedListWidget<CustomerWalletTransactionModel>(
                        items: state.transactions,
                        isLoading: state.isLoading,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        errorMessage: state.errorMessage,
                        emptyMessage: l10n.walletEmpty,
                        emptyIcon: Icons.account_balance_wallet_outlined,
                        padding: const EdgeInsets.fromLTRB(
                          AppConstants.paddingL,
                          AppConstants.paddingL,
                          AppConstants.paddingL,
                          AppConstants.paddingL,
                        ),
                        onLoadMore: cubit.loadMore,
                        onRetry: cubit.initialize,
                        onRefresh: cubit.refresh,
                        itemBuilder: (context, transaction, _) =>
                            CustomerWalletTransactionRowWidget(
                              transaction: transaction,
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
