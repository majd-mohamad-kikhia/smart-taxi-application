import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/booking_header_widget.dart';
import '../widgets/booking_map_widget.dart';
import '../widgets/confirm_booking_button_widget.dart';
import '../widgets/payment_and_notes_widget.dart';
import '../widgets/promo_banner_widget.dart';
import '../widgets/ride_category_selector_widget.dart';
import '../widgets/route_summary_widget.dart';

/// Confirm Booking screen – map route + ride category selection + CTA.
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingCubit>(
      create: (_) => sl<BookingCubit>()..initialize(),
      child: const _BookingView(),
    );
  }
}

class _BookingView extends StatelessWidget {
  const _BookingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: BlocConsumer<BookingCubit, BookingState>(
        listenWhen: (prev, curr) =>
            prev.isConfirmed != curr.isConfirmed && curr.isConfirmed,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تأكيد طلب مشوار ${state.selectedCategory.name} بنجاح ✓',
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pushReplacementNamed(AppRouter.tracking);
        },
        builder: (context, state) {
          return Column(
            children: [
              // ── Map (top ~42%) ──────────────────────────
              Expanded(
                flex: 42,
                child: Stack(
                  children: [
                    BookingMapWidget(route: state.route),
                    BookingHeaderWidget(
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              // ── Bottom sheet panel ─────────────────────
              Expanded(
                flex: 58,
                child: _BookingSheet(state: state),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingSheet extends StatelessWidget {
  final BookingState state;

  const _BookingSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RouteSummaryWidget(
                    route: state.route,
                    onSwap: () => context.read<BookingCubit>().swapRoute(),
                  ),
                  const SizedBox(height: 16),
                  RideCategorySelectorWidget(
                    categories: state.categories,
                    selectedId: state.selectedCategoryId,
                    onSelected: (id) =>
                        context.read<BookingCubit>().selectCategory(id),
                  ),
                  const SizedBox(height: 14),
                  if (state.promoLabel != null)
                    PromoBannerWidget(
                      label: state.promoLabel!,
                      discountAmount: state.promoDiscount,
                    ),
                  const SizedBox(height: 12),
                  PaymentAndNotesWidget(
                    paymentMethod: state.paymentMethod,
                    walletBalance: state.walletBalance,
                    captainNote: state.captainNote,
                  ),
                  const SizedBox(height: 16),
                  ConfirmBookingButtonWidget(
                    categoryName: state.selectedCategory.name,
                    price: state.finalPrice,
                    isLoading: state.isConfirming,
                    onConfirm: () =>
                        context.read<BookingCubit>().confirmBooking(),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
