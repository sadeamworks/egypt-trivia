import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../providers/game_provider.dart';
import '../../providers/daily_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../../routing/routes.dart';
import '../../widgets/common/egyptian_background.dart';

/// Home screen with category selection
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Category> _availableCategories = [
    const Category(id: 'history', nameAr: 'تاريخ مصر', icon: '🏛️'),
    const Category(id: 'geography', nameAr: 'جغرافيا', icon: '🗺️'),
    const Category(id: 'monuments', nameAr: 'أهرامات وآثار', icon: '🏜️'),
    const Category(id: 'islamic', nameAr: 'إسلاميات', icon: '🕌'),
    const Category(id: 'popculture', nameAr: 'ثقافة شعبية', icon: '🎭'),
    const Category(id: 'cinema', nameAr: 'أفلام مصرية', icon: '🎬'),
    const Category(id: 'football', nameAr: 'كرة قدم', icon: '⚽'),
    const Category(id: 'proverbs', nameAr: 'أمثال شعبية', icon: '🗣️'),
  ];

  @override
  Widget build(BuildContext context) {
    final dailyStreakAsync = ref.watch(dailyStreakProvider);
    final achievementState = ref.watch(achievementProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: EgyptianBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildLogo(context),
                    const SizedBox(height: 20),
                    _buildDailyChallenge(context, dailyStreakAsync),
                    const SizedBox(height: 24),
                    _buildQuickActions(context, achievementState),
                    const SizedBox(height: 16),
                    _buildCategoryGrid(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldDark.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.change_history,
                      color: Colors.white,
                      size: 32 - (index * 4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'تريفيا مصر',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'اختبر معرفتك بمصر',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDailyChallenge(BuildContext context, AsyncValue<int> streakAsync) {
    final streak = streakAsync.valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => context.push(Routes.daily),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gold, AppColors.goldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التحدي اليومي',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (streak > 0)
                    Text(
                      '🔥 $streak أيام متتالية',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'العب الآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AchievementState achievementState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.emoji_events,
              label: 'الإنجازات',
              badge: '${achievementState.totalUnlocked}/${achievementState.totalAchievements}',
              onTap: () => context.push(Routes.achievements),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.papyrus,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppColors.gold, size: 28),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر قسم',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _availableCategories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(context, _availableCategories[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return GestureDetector(
      onTap: () => _startGame(context, category.nameAr),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.papyrus,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              category.nameAr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, String categoryName) {
    ref.read(gameProvider.notifier).startGame(categoryName: categoryName);
    context.push(Routes.game);
  }
}
