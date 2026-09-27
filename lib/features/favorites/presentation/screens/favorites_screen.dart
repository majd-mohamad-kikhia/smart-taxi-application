import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../widgets/add_address_card_widget.dart';
import '../widgets/favorite_address_card_widget.dart';
import '../widgets/favorites_header_widget.dart';
import '../widgets/save_current_location_widget.dart';

/// Favorite / Saved Addresses management screen.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoritesCubit>(
      create: (_) => sl<FavoritesCubit>()..initialize(),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: BlocConsumer<FavoritesCubit, FavoritesState>(
        listenWhen: (prev, curr) =>
            prev.deletedId != curr.deletedId && curr.deletedId != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم حذف العنوان'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          context.read<FavoritesCubit>().clearDeletedFlag();
        },
        builder: (context, state) {
          return Column(
            children: [
              FavoritesHeaderWidget(
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    AddAddressCardWidget(
                      onSelectOnMap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تحديد على الخريطة قريباً'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      onSearchByName: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('البحث بالاسم قريباً'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    // Section header
                    Row(
                      children: [
                        const Text(
                          'العناوين المفضلة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.count} أماكن',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              context.read<FavoritesCubit>().sortByName(),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.swap_vert_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'ترتيب',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.addresses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'لا توجد عناوين محفوظة',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ...state.addresses.map(
                        (address) => FavoriteAddressCardWidget(
                          address: address,
                          onEdit: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تعديل ${address.name} قريباً'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          onDelete: () => _confirmDelete(context, address.id, address.name),
                          onOrderRide: () {
                            Navigator.of(context).pushNamed(AppRouter.booking);
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    SaveCurrentLocationWidget(
                      areaLabel: state.currentAreaLabel,
                      isSaving: state.isSavingCurrent,
                      onSave: () async {
                        await context
                            .read<FavoritesCubit>()
                            .saveCurrentLocation();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('تم حفظ الموقع الحالي ✓'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showAppDialog(
      context: context,
      title: 'حذف العنوان؟',
      message: 'هل تريد حذف "$name" من عناوينك المفضلة؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      cancelLabel: 'تراجع',
      icon: Icons.delete_rounded,
      tone: AppDialogTone.destructive,
      onConfirm: () => context.read<FavoritesCubit>().deleteAddress(id),
    );
  }
}
