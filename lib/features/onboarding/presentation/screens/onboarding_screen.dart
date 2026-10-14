import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/page_dots_indicator_widget.dart';
import '../../data/models/onboarding_step.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_action_button_widget.dart';
import '../widgets/onboarding_page_widget.dart';
import '../widgets/onboarding_top_bar_widget.dart';

/// The first-launch introduction: a few swipeable pages shown once, before
/// role selection. Next moves on, Skip or finishing the last page hands over
/// to role selection.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingCubit>(
      create: (_) => sl<OnboardingCubit>(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  static const Duration _pageDuration = Duration(milliseconds: 320);

  final PageController _pageController = PageController();
  bool _leaving = false;

  OnboardingCubit get _cubit => context.read<OnboardingCubit>();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_cubit.isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: _pageDuration, curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    await _cubit.complete();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                BlocSelector<OnboardingCubit, int, int>(
                  selector: (page) => page,
                  builder: (context, page) => OnboardingTopBarWidget(
                    page: page,
                    pageCount: OnboardingStep.count,
                    onSkip: _finish,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: OnboardingStep.count,
                    onPageChanged: _cubit.pageChanged,
                    itemBuilder: (_, index) =>
                        OnboardingPageWidget(step: OnboardingStep.values[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.paddingXL,
                    AppConstants.paddingXL,
                    AppConstants.paddingXL,
                    AppConstants.paddingXXL,
                  ),
                  child: BlocSelector<OnboardingCubit, int, int>(
                    selector: (page) => page,
                    builder: (context, page) {
                      final isLast = page == OnboardingStep.count - 1;
                      final l10n = context.l10n;
                      return Column(
                        children: [
                          PageDotsIndicatorWidget(
                            count: OnboardingStep.count,
                            index: page,
                          ),
                          const SizedBox(height: AppConstants.paddingXL),
                          OnboardingActionButtonWidget(
                            label: isLast
                                ? l10n.onboardingGetStarted
                                : l10n.onboardingNext,
                            onPressed: _next,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
