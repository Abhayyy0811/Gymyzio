import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../providers/app_settings_provider.dart';
import '../models/exercise.dart';
import '../widgets/exercise_card.dart';
import '../widgets/exercise_skeleton_widget.dart';

import '../widgets/responsive_web_wrapper.dart';

import '../widgets/app_notification_bell.dart';

final isCompactListViewProvider = StateProvider<bool>((ref) => false);

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredExercisesAsync = ref.watch(filteredExercisesProvider);
    final selectedMuscle = ref.watch(selectedMuscleFilterProvider);
    final selectedEquipment = ref.watch(selectedEquipmentFilterProvider);
    final favorites = ref.watch(favoriteExercisesProvider);
    final tr = ref.watch(trProvider);

    final allExercises = ref.watch(exerciseListProvider).asData?.value ?? [];
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final strengthCount = allExercises.where((e) => e.category == ExerciseCategory.strength).length;
    final cardioCount = allExercises.where((e) => e.category == ExerciseCategory.cardio).length;

    // Compute dynamic equipment variants for the currently selected muscle group
    List<String> equipmentListForMuscle = ['All'];
    if (selectedMuscle != 'All') {
      final mLower = selectedMuscle.toLowerCase();
      final muscleExercises = allExercises.where((ex) {
        return ex.muscleGroup.toLowerCase().contains(mLower) ||
            (ex.bodyPart != null && ex.bodyPart!.toLowerCase().contains(mLower));
      }).toList();

      final eqSet = muscleExercises.map((e) => e.equipment).toSet().toList()..sort();
      equipmentListForMuscle.addAll(eqSet);
    }

    const accentColor = AppColors.libraryAccent;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradientOf(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr('exercise_library'), style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold, letterSpacing: -0.3)),
          elevation: 0,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: AppNotificationBell(),
            ),
          ],
        ),
        body: ResponsiveWebWrapper(
          maxWidth: 1050,
          child: Column(
            children: [
            // Search Bar & Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Input Field
                  TextField(
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                    decoration: InputDecoration(
                      hintText: tr('search_hint'),
                      prefixIcon: const Icon(Icons.search_rounded, color: accentColor),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: accentColor, width: 2),
                      ),
                      suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips (All, Strength, Cardio) + Grid Toggle & Filter Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Strength', 'Cardio'].map((cat) {
                              int count = allExercises.length;
                              if (cat == 'Strength') count = strengthCount;
                              if (cat == 'Cardio') count = cardioCount;
                              final isSelected = selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text('$cat ($count)'),
                                  selected: isSelected,
                                  selectedColor: accentColor,
                                  backgroundColor: AppColors.surfaceLightOf(context),
                                  side: BorderSide(
                                    color: isSelected ? accentColor : AppColors.borderOf(context),
                                  ),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.black : AppColors.textSecondaryOf(context),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      ref.read(selectedCategoryFilterProvider.notifier).state = cat;
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Compact / Grid View Toggle Button
                      Consumer(
                        builder: (context, ref, child) {
                          final isCompact = ref.watch(isCompactListViewProvider);
                          return AppBouncyTap(
                            onTap: () {
                              ref.read(isCompactListViewProvider.notifier).state = !isCompact;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLightOf(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderOf(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCompact ? Icons.view_headline_rounded : Icons.grid_view_rounded,
                                    size: 18,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isCompact ? 'List' : 'Grid',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),

                      // Filter Bottom Sheet Button
                      AppBouncyTap(
                        onTap: () => _showMuscleGroupBottomSheet(context, ref, allExercises, selectedMuscle),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLightOf(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderOf(context)),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Equipment Sub-Filter Chips Row (Appears ONLY when a specific muscle group is selected)
                  if (selectedMuscle != 'All' && equipmentListForMuscle.length > 1) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: equipmentListForMuscle.map((eq) {
                          final isSelected = selectedEquipment == eq;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(eq == 'All' ? 'All Equipment' : eq),
                              selected: isSelected,
                              selectedColor: accentColor.withValues(alpha: 0.3),
                              backgroundColor: AppColors.surfaceLightOf(context),
                              side: BorderSide(
                                color: isSelected ? accentColor : AppColors.borderOf(context),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? accentColor : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (bool selected) {
                                if (selected) {
                                  ref.read(selectedEquipmentFilterProvider.notifier).state = eq;
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Exercise List with Async Handling, Pagination & Pull-To-Refresh
            Expanded(
              child: filteredExercisesAsync.when(
                loading: () => const ExerciseSkeletonWidget(itemCount: 8),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load exercises',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(exerciseListProvider.notifier).loadExercises(forceRefresh: true);
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                          label: const Text('Retry Fetching', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (filteredExercises) {
                  if (filteredExercises.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('No exercises match your search', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return PaginatedExerciseListView(
                    exercises: filteredExercises,
                    favorites: favorites,
                    accentColor: accentColor,
                    onRefresh: () async {
                      await ref.read(exerciseListProvider.notifier).loadExercises(forceRefresh: true);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showMuscleGroupBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<Exercise> allExercises,
    String currentSelectedMuscle,
  ) {
    final muscleGroups = [
      'All',
      'Chest',
      'Back',
      'Legs',
      'Shoulders',
      'Arms',
      'Core',
      'Cardio',
      'Upper Arms',
      'Lower Arms',
      'Upper Legs',
      'Lower Legs',
      'Waist',
      'Neck'
    ];
    const accentColor = AppColors.libraryAccent;

    int getMuscleCount(String m) {
      if (m == 'All') return allExercises.length;
      final mLower = m.toLowerCase();
      return allExercises.where((ex) {
        return ex.muscleGroup.toLowerCase().contains(mLower) ||
            (ex.bodyPart != null && ex.bodyPart!.toLowerCase().contains(mLower));
      }).length;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        String filterText = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredGroups = muscleGroups.where((m) {
              if (filterText.isEmpty) return true;
              return m.toLowerCase().contains(filterText.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Handle indicator & title
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderOf(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Muscle Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context))),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: AppColors.textMutedOf(context)),
                            onPressed: () => Navigator.of(modalCtx).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        style: TextStyle(fontSize: 14, color: AppColors.textPrimaryOf(context)),
                        decoration: InputDecoration(
                          hintText: 'Filter muscle groups...',
                          hintStyle: TextStyle(color: AppColors.textMutedOf(context)),
                          prefixIcon: const Icon(Icons.search_rounded, color: accentColor, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: AppColors.surfaceLightOf(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            filterText = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Muscle Groups List wrapped in Material to prevent ListTile assertion errors
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredGroups.length,
                        itemBuilder: (ctx, index) {
                          final m = filteredGroups[index];
                          final count = getMuscleCount(m);
                          final isSelected = currentSelectedMuscle == m;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                              title: Text(
                                m,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? accentColor : AppColors.textPrimaryOf(context),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? accentColor : accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '($count)',
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
                                  ],
                                ],
                              ),
                              onTap: () {
                                ref.read(selectedMuscleFilterProvider.notifier).state = m;
                                ref.read(selectedEquipmentFilterProvider.notifier).state = 'All';
                                Navigator.of(modalCtx).pop();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Paginated infinite scrolling ListView for rendering full exercise database smoothly
class PaginatedExerciseListView extends StatefulWidget {
  final List<Exercise> exercises;
  final Set<String> favorites;
  final Color accentColor;
  final Future<void> Function() onRefresh;

  const PaginatedExerciseListView({
    super.key,
    required this.exercises,
    required this.favorites,
    required this.accentColor,
    required this.onRefresh,
  });

  @override
  State<PaginatedExerciseListView> createState() => _PaginatedExerciseListViewState();
}

class _PaginatedExerciseListViewState extends State<PaginatedExerciseListView> {
  final ScrollController _scrollController = ScrollController();
  int _displayedCount = 40;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PaginatedExerciseListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercises.length != widget.exercises.length) {
      setState(() {
        _displayedCount = 40.clamp(0, widget.exercises.length);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (_displayedCount < widget.exercises.length) {
        setState(() {
          _displayedCount = (_displayedCount + 30).clamp(0, widget.exercises.length);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.exercises.length;
    final renderCount = _displayedCount.clamp(0, totalCount);
    final hasMore = renderCount < totalCount;

    return Consumer(
      builder: (context, ref, child) {
        final isCompact = ref.watch(isCompactListViewProvider);

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 1;
            if (isCompact) {
              crossAxisCount = width >= 900 ? 3 : (width >= 550 ? 2 : 1);
            } else {
              crossAxisCount = width >= 900 ? 3 : (width >= 550 ? 2 : 1);
            }

            return RefreshIndicator(
              color: widget.accentColor,
              backgroundColor: AppColors.surface,
              onRefresh: widget.onRefresh,
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: isCompact ? 68 : (crossAxisCount == 1 ? 100 : 110),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: hasMore ? renderCount + 1 : renderCount,
                itemBuilder: (context, index) {
                  if (index == renderCount && hasMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.libraryAccent,
                          ),
                        ),
                      ),
                    );
                  }

                  final exercise = widget.exercises[index];
                  final isFav = widget.favorites.contains(exercise.id);

                  return ExerciseCard(
                    exercise: exercise,
                    isFavorite: isFav,
                    accentColor: widget.accentColor,
                    isCompact: isCompact,
                    onTap: () {
                      context.push('/exercise-detail/${exercise.id}');
                    },
                    onFavoriteToggle: () {
                      ref.read(favoriteExercisesProvider.notifier).toggleFavorite(exercise.id);
                    },
                  ).animate().fadeIn(duration: 300.ms, delay: (15 * (index % 8)).ms);
                },
              ),
            );
          },
        );
      },
    );
  }
}
