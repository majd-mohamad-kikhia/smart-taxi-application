import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// Optional directions the map can't show: building, floor, landmark.
class AddressDetailsFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;

  const AddressDetailsFieldWidget({
    super.key,
    required this.controller,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: 2,
      minLines: 1,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        labelText: context.l10n.addressDetailsLabel,
        hintText: context.l10n.addressDetailsHint,
        prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
      ),
    );
  }
}
