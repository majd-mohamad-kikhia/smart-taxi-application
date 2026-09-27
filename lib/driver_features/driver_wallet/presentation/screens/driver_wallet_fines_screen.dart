import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/paginated_list_widget.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../cubit/driver_wallet_cubit.dart';
import '../cubit/driver_wallet_state.dart';
import '../widgets/wallet_transaction_row_widget.dart';

/// Driver's administrative fines — `GET /api/driver/wallet` filtered to
/// `transaction_type=penalty`, reached by tapping the fines card on the
/// wallet statement screen.
class DriverWalletFinesScreen extends StatelessWidget {
  const DriverWalletFinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverWalletCubit>(
      create: (_) => sl<DriverWalletCubit>(param1: WalletTransactionType.penalty)
        ..initialize(),
      child: const _DriverWalletFinesView(),
    );
  }
}

class _DriverWalletFinesView extends StatelessWidget {
  const _DriverWalletFinesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: const Text('الغرامات الإدارية')),
      body: BlocBuilder<DriverWalletCubit, DriverWalletState>(
        builder: (context, state) {
          return PaginatedListWidget<WalletTransactionModel>(
            items: state.transactions,
            isLoading: state.isLoading,
            isLoadingMore: state.isLoadingMore,
            hasMore: state.hasMore,
            errorMessage: state.errorMessage,
            emptyMessage: 'لا توجد غرامات',
            emptyIcon: Icons.verified_outlined,
            onRetry: () => context.read<DriverWalletCubit>().initialize(),
            onRefresh: () => context.read<DriverWalletCubit>().refresh(),
            onLoadMore: () => context.read<DriverWalletCubit>().loadMore(),
            itemBuilder: (context, transaction, index) =>
                WalletTransactionRowWidget(transaction: transaction),
          );
        },
      ),
    );
  }
}
