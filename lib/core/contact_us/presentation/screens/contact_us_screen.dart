import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_constants.dart';
import '../../../enums/user_role.dart';
import '../../../injection/injection.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_loader_widget.dart';
import '../../data/models/contact_number_model.dart';
import '../cubit/contact_us_cubit.dart';
import '../cubit/contact_us_state.dart';
import '../widgets/contact_number_tile_widget.dart';
import '../widgets/contact_us_error_widget.dart';

/// The manager's "Contact us" numbers for [role]'s app — tap one to call it
/// or open WhatsApp. Shared by both roles' settings screens.
class ContactUsScreen extends StatelessWidget {
  final UserRole role;

  const ContactUsScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ContactUsCubit>(
      create: (_) => sl<ContactUsCubit>(
        instanceName: ContactUsApp.fromRole(role).wireValue,
      ),
      child: const _ContactUsView(),
    );
  }
}

class _ContactUsView extends StatefulWidget {
  const _ContactUsView();

  @override
  State<_ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<_ContactUsView> {
  String? _loadedLang;

  String get _lang => Localizations.localeOf(context).languageCode;

  /// Loads on open and again after the app language changes (a different
  /// language is a full list; the same one is a cheap `304`).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = _lang;
    if (_loadedLang == lang) return;
    _loadedLang = lang;
    context.read<ContactUsCubit>().load(lang: lang);
  }

  Future<void> _reload() => context.read<ContactUsCubit>().load(lang: _lang);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: Text(context.l10n.contactUs)),
      body: BlocBuilder<ContactUsCubit, ContactUsState>(
        builder: (context, state) => switch (state) {
          ContactUsLoading() => const AppLoaderWidget(),
          ContactUsError(:final message) => ContactUsErrorWidget(
            message: message,
            onRetry: _reload,
          ),
          ContactUsLoaded(:final numbers) when numbers.isEmpty => Center(
            child: Text(
              context.l10n.noContactNumbers,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ContactUsLoaded(:final numbers) => RefreshIndicator(
            onRefresh: _reload,
            child: _ContactNumbersGrid(numbers: numbers),
          ),
        },
      ),
    );
  }
}

/// One column on phones, two or three on tablets / web.
class _ContactNumbersGrid extends StatelessWidget {
  static const double _minTileWidth = 360;
  static const double _tileHeight = 76;

  final List<ContactNumberModel> numbers;

  const _ContactNumbersGrid({required this.numbers});

  @override
  Widget build(BuildContext context) {
    // Taller tiles when the user scales text up, so labels never clip.
    final tileHeight = MediaQuery.textScalerOf(context).scale(_tileHeight);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minTileWidth).floor().clamp(
          1,
          3,
        );
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingL),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: tileHeight,
            crossAxisSpacing: AppConstants.paddingM,
            mainAxisSpacing: AppConstants.paddingM,
          ),
          itemCount: numbers.length,
          itemBuilder: (_, i) => ContactNumberTileWidget(number: numbers[i]),
        );
      },
    );
  }
}
