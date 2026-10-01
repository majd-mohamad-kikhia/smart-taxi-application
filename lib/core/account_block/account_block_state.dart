import 'package:equatable/equatable.dart';
import '../models/account_block_model.dart';

class AccountBlockState extends Equatable {
  final AccountBlockModel block;

  const AccountBlockState({this.block = AccountBlockModel.none});

  bool get isBlocked => block.isBlocked;

  @override
  List<Object?> get props => [block];
}
