import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/gym_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui_components.dart';

class TrainTab extends StatefulWidget {
  const TrainTab({super.key});

  @override
  State<TrainTab> createState() => _TrainTabState();
}

class _TrainTabState extends State<TrainTab> {
  String _mode = 'workout';
  late String _selectedDay;
  Map<String, bool> _completedExercises = {};

  final List<({String key, String short})> _week = const [
    (key: 'monday', short: 'Mon'),
    (key: 'tuesday', short: 'Tue'),
    (key: 'wednesday', short: 'Wed'),
    (key: 'thursday', short: 'Thu'),
    (key: 'friday', short: 'Fri'),
    (key: 'saturday', short: 'Sat'),
    (key: 'sunday', short: 'Sun'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = AppFormat.todayWeekday();
    _loadChecklist();
  }

  String _getChecklistKey(String? planId) {
    return 'workout_done_${planId ?? "unknown"}_${AppFormat.todayKey()}';
  }

  Future<void> _loadChecklist() async {
    final gym = Provider.of<GymProvider>(context, listen: false);
    final planId = gym.fitness?.workout?.id;
    final key = _getChecklistKey(planId);
    final saved = await StorageService.getString(key);
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        setState(() {
          _completedExercises = decoded.map((k, v) => MapEntry(k, v == true));
        });
      } catch (_) {}
    }
  }

  Future<void> _toggleExercise(int index, String? planId) async {
    final strIndex = index.toString();
    final current = _completedExercises[strIndex] ?? false;
    final next = !current;

    if (next) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _completedExercises[strIndex] = next;
    });

    final key = _getChecklistKey(planId);
    await StorageService.setString(key, jsonEncode(_completedExercises));
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final todayDayKey = AppFormat.todayWeekday();

    if (gym.isLoadingFitness && gym.fitness == null) {
      return const Scaffold(body: LoadingBlock());
    }

    if (gym.fitnessError != null && gym.fitness == null) {
      return Scaffold(
        body: ErrorStateView(
          message: gym.fitnessError,
          onRetry: () => gym.fetchFitness(),
        ),
      );
    }

    final workout = gym.fitness?.workout;
    final diet = gym.fitness?.diet;
    final routine = workout?.routine;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => gym.fetchFitness(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenTitle(title: 'Train & Diet', subtitle: 'Your workout and nutrition plans'),
              const SizedBox(height: 16),
              SegmentedPicker<String>(
                options: const [
                  (value: 'workout', label: 'Workout plan', icon: Icons.fitness_center),
                  (value: 'diet', label: 'Diet plan', icon: Icons.restaurant_menu),
                ],
                selected: _mode,
                onSelected: (val) => setState(() => _mode = val),
              ),
              const SizedBox(height: 20),

              if (_mode == 'workout')
                _buildWorkoutView(workout, routine, todayDayKey)
              else
                _buildDietView(diet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutView(WorkoutPlan? workout, WorkoutRoutine? routine, String todayDayKey) {
    if (workout == null) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.fitness_center_outlined,
          title: 'No workout plan yet',
          message: 'Your trainer will assign a personalised plan. Check back soon.',
        ),
      );
    }

    final dayData = routine?.days[_selectedDay];
    final isToday = _selectedDay == todayDayKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Plan Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR PLAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workout.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (workout.difficulty != null)
                    _buildPill(AppFormat.titleCase(workout.difficulty)),
                  if (workout.targetBodyShape != null)
                    _buildPill(workout.targetBodyShape!),
                ],
              ),
              if (workout.description != null && workout.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  workout.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xDDFFFFFF),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (routine != null) ...[
          // Week Strip
          Row(
            children: _week.map((d) {
              final isSelected = d.key == _selectedDay;
              final isRest = routine.days[d.key]?.isRestDay ?? false;
              final isCurrentToday = d.key == todayDayKey;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDay = d.key);
                    },
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            d.short,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.white
                                  : isCurrentToday
                                      ? AppColors.accent
                                      : isRest
                                          ? AppColors.border
                                          : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Day View
          if (dayData != null)
            _buildDayView(dayData, workout.id, isToday)
          else
            const AppCard(
              child: EmptyStateView(
                icon: Icons.coffee_outlined,
                title: 'Rest day',
                message: 'No routine defined for this day.',
              ),
            ),
        ] else if (workout.details != null && workout.details!.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Routine Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(workout.details!, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayView(RoutineDay day, String planId, bool isToday) {
    if (day.isRestDay || day.exercises.isEmpty) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.coffee_outlined,
          title: 'Rest day',
          message: 'Recovery is where the gains happen. Stretch, hydrate and sleep well.',
        ),
      );
    }

    final total = day.exercises.length;
    final completedCount = isToday
        ? day.exercises.asMap().entries.where((e) => _completedExercises[e.key.toString()] == true).length
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.label.isNotEmpty ? day.label : 'Workout',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$total exercises',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (isToday)
                    AppBadge(
                      text: '$completedCount/$total done',
                      tone: completedCount == total ? BadgeTone.success : BadgeTone.info,
                    ),
                ],
              ),
              if (isToday) ...[
                const SizedBox(height: 14),
                AppProgressBar(
                  value: total > 0 ? completedCount / total : 0,
                  color: completedCount == total ? AppColors.success : AppColors.primary,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        ...day.exercises.asMap().entries.map((entry) {
          final i = entry.key;
          final ex = entry.value;
          final isChecked = isToday && (_completedExercises[i.toString()] == true);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              backgroundColor: isChecked ? const Color(0xFFF4FBF7) : AppColors.surface,
              borderColor: isChecked ? const Color(0xFFCBEBD8) : AppColors.border,
              onTap: isToday ? () => _toggleExercise(i, planId) : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isChecked ? AppColors.success : AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: isChecked
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isChecked ? AppColors.textMuted : AppColors.text,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildExerciseChip(Icons.layers_outlined, '${ex.sets} sets'),
                            _buildExerciseChip(Icons.repeat, '${ex.reps} reps'),
                            if (ex.restSeconds > 0)
                              _buildExerciseChip(Icons.timer_outlined, '${ex.restSeconds}s rest'),
                          ],
                        ),
                        if (ex.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            ex.notes,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        if (isToday)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Tap an exercise to tick it off.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _buildDietView(DietPlan? diet) {
    if (diet == null) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.restaurant_outlined,
          title: 'No diet plan yet',
          message: 'Ask your trainer to build a nutrition plan for your goal.',
        ),
      );
    }

    final lines = (diet.details ?? '')
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nutrition Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B6B3A), Color(0xFF12A150)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR NUTRITION PLAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                diet.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              if (diet.targetGoal != null) ...[
                const SizedBox(height: 10),
                _buildPill(diet.targetGoal!),
              ],
              if (diet.description != null && diet.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  diet.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xDDFFFFFF),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calorie Card
        if (diet.calories != null) ...[
          AppCard(
            child: Row(
              children: [
                const IconBubble(
                  name: Icons.local_fire_department,
                  color: Color(0xFFE8590C),
                  bg: Color(0xFFFFEDE0),
                  size: 48,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${diet.calories} kcal',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const Text(
                      'Daily target',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Structured Meal Cards + Tips (with legacy details fallback)
        if (diet.mealPlan != null && diet.mealPlan!.meals.isNotEmpty) ...[
          for (final meal in diet.mealPlan!.meals) ...[
            _buildMealCard(meal),
            const SizedBox(height: 12),
          ],
          if (diet.mealPlan!.tips.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildDietTipsCard(diet.mealPlan!.tips),
          ],
        ] else if (lines.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meal guide',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                ...lines.map((line) {
                  final cleanLine = line.replaceFirst(RegExp(r'^[-•*]\s*'), '');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 6, right: 10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            cleanLine,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMealCard(DietMeal meal) {
    final hasTime = meal.time.trim().isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (hasTime) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        meal.time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (meal.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < meal.items.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == meal.items.length - 1 ? 0 : 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 7, right: 10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        meal.items[i],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDietTipsCard(List<String> tips) {
    return AppCard(
      backgroundColor: AppColors.warningSoft.withValues(alpha: 0.55),
      borderColor: const Color(0xFFF6DDAA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBubble(
                name: Icons.lightbulb_outline_rounded,
                color: AppColors.warning,
                bg: Color(0xFFFFE6B8),
                size: 36,
              ),
              SizedBox(width: 10),
              Text(
                'Tips & Guidelines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tips.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == tips.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tips[i],
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildExerciseChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
