import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../utils/format_price.dart';
import 'meta_item_widget.dart';

/// "Includes extra passengers fee: 20 new SYP" — the office's charge for 5
/// or 6 people, shown next to an order's price, which already contains it.
class PassengersFeeMetaWidget extends StatelessWidget {
  final double fee;

  const PassengersFeeMetaWidget({super.key, required this.fee});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MetaItemWidget(
      icon: Icons.group_add_rounded,
      label: l10n.farePassengersFeeIncluded(formatSyp(l10n, fee)),
    );
  }
}
