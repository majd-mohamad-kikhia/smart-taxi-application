import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../account_block/account_block_cubit.dart';
import '../account_block/account_block_state.dart';
import '../injection/injection.dart';
import '../models/account_block_model.dart';
import '../contact_us/data/models/contact_number_model.dart';
import 'account_blocked_widget.dart';

/// Swaps [child] for the "blocked until …" panel while the signed-in
/// account is blocked, and back as soon as the block ends. Rebuilds only
/// when the block itself changes. [blockedMessage] explains the block for
/// the current role (see `AccountBlockedWidget`).
class AccountBlockGateWidget extends StatelessWidget {
  final String blockedMessage;
  final ContactUsApp contactApp;
  final Widget child;

  const AccountBlockGateWidget({
    super.key,
    required this.blockedMessage,
    required this.contactApp,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AccountBlockCubit, AccountBlockState, AccountBlockModel>(
      bloc: sl<AccountBlockCubit>(),
      selector: (state) => state.block,
      builder: (context, block) {
        if (!block.isBlocked) return child;
        return AccountBlockedWidget(
          block: block,
          message: blockedMessage,
          contactApp: contactApp,
        );
      },
    );
  }
}
