/// Plan page — uniform card sizing, swipe-to-reveal delete, grid day cells.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/localization/built_in_exercise_localizations.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/localization/localized_error.dart';
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/redesign/pages/plan/exercise_picker_page.dart';
import 'package:yours/redesign/pages/plan/local_gym_mode_page.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';
part 'plan_page/plan_list_widgets.dart';
part 'plan_page/plan_detail_page.dart';
part 'plan_page/plan_edit_page.dart';
part 'plan_page/day_edit_page.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

typedef TrainingDay = LocalTrainingDayModel;
typedef AppPlan = LocalTrainingPlanModel;

// ═══════════════════════════════════════════════════════════════════════════════
// Plan Page
// ═══════════════════════════════════════════════════════════════════════════════

class PlanPage extends StatefulWidget {
  const PlanPage({super.key, this.repository});

  final LocalTrainingRepository? repository;

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late final LocalTrainingRepository _repository;
  late final Future<void> _initFuture;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LocalTrainingRepository(locator<LocalTrainingDatabase>());
    _initFuture = _repository.ensureSeedData();
  }

  void _editPlan(AppPlan source) async {
    final plan = source.deepCopy();
    final result = await Navigator.of(context).push<AppPlan>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlanEditPage(plan: plan),
      ),
    );
    if (result != null && mounted) {
      try {
        await _repository.savePlan(result);
      } on Object catch (error) {
        _showLocalSaveError(error);
      }
    }
  }

  void _createPlan() async {
    final plan = AppPlan(name: context.l10n.planNewName, totalWeeks: 4, daysPerWeek: 4);
    final result = await Navigator.of(context).push<AppPlan>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlanEditPage(plan: plan),
      ),
    );
    if (result != null && mounted) {
      try {
        await _repository.savePlan(result);
      } on Object catch (error) {
        _showLocalSaveError(error);
      }
    }
  }

  Future<bool> _deletePlan(AppPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.planDeleteTitle),
        content: Text(context.l10n.planDeleteMessage(plan.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(
              context.l10n.commonDelete,
              style: context
                  .yoursText(YoursTextRole.body)
                  .copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && plan.id != null) {
      try {
        await _repository.deletePlan(plan.id!);
        return true;
      } on Object catch (error) {
        _showLocalSaveError(error);
      }
    }
    return false;
  }

  Future<void> _setPlanArchived(AppPlan plan, bool archived) async {
    if (plan.id == null) {
      return;
    }
    try {
      await _repository.setPlanArchived(plan.id!, archived);
    } on Object catch (error) {
      _showLocalSaveError(error);
    }
  }

  void _showLocalSaveError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.planLocalSaveFailed(localizedErrorDetail(context, error)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPlanDetail(AppPlan plan) {
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanDetailPage(plan: plan.deepCopy()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (initSnapshot.hasError) {
          return _hint(
            context.l10n.planDatabaseInitFailed(
              localizedErrorDetail(context, initSnapshot.error!),
            ),
          );
        }

        return StreamBuilder<List<AppPlan>>(
          stream: _repository.watchPlans(archived: _showArchived),
          builder: (context, snapshot) {
            final plans = snapshot.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YoursPageHeader(
                    title: context.l10n.planTitle,
                    subtitle: plans.isEmpty
                        ? context.l10n.planNone
                        : context.l10n.planCount(plans.length),
                    trailing: TextButton(
                      key: const ValueKey('plan-create'),
                      onPressed: _createPlan,
                      child: Text(
                        context.l10n.planCreate,
                        style: context.yoursText(YoursTextRole.button, tone: YoursTone.accent),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: YoursSegmentedFilter<bool>(
                      key: const ValueKey('plan-archive-filter'),
                      segments: [
                        (false, context.l10n.planActive),
                        (true, context.l10n.planArchived),
                      ],
                      selected: _showArchived,
                      onChanged: (value) => setState(() => _showArchived = value),
                    ),
                  ),

                  if (plans.isEmpty)
                    YoursEmptyState(
                      key: const ValueKey('plan-empty-state'),
                      message: _showArchived
                          ? context.l10n.planNoArchived
                          : context.l10n.planNoActive,
                      icon: Icons.event_note_outlined,
                      actionLabel: _showArchived ? null : context.l10n.planCreate,
                      onAction: _showArchived ? null : _createPlan,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        context.l10n.planSwipeHint,
                        style: context
                            .yoursText(YoursTextRole.body)
                            .copyWith(
                              fontSize: 13,
                              color: palette.muted,
                            ),
                      ),
                    ),
                  if (plans.isNotEmpty)
                    ...List.generate(plans.length, (i) {
                      final p = plans[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SwipeActionsWrapper(
                          key: ValueKey('plan_${p.id ?? i}'),
                          onEdit: () => _editPlan(p),
                          onDelete: () async => _deletePlan(p),
                          child: GestureDetector(
                            onTap: () => _openPlanDetail(p),
                            child: YoursListActionCard(
                              key: ValueKey('plan-card-${p.id ?? i}'),
                              title: p.name,
                              subtitle: context.l10n.planSummary(p.totalWeeks, p.daysPerWeek),
                              detail: p.syncStatus == localSyncPending
                                  ? context.l10n.commonPendingSync
                                  : context.l10n.commonSynced,
                              status: YoursStatusPill(
                                label: p.hasFullSchedule
                                    ? context.l10n.planScheduleReady
                                    : context.l10n.planScheduleIncomplete,
                                tone: p.hasFullSchedule ? YoursTone.success : YoursTone.accent,
                              ),
                              minHeight: 110,
                              shadow: true,
                              trailing: PopupMenuButton<String>(
                                key: ValueKey('plan-menu-${p.id ?? i}'),
                                tooltip: _showArchived
                                    ? context.l10n.planRestoreActive
                                    : context.l10n.planArchive,
                                onSelected: (value) {
                                  if (value == 'archive') {
                                    _setPlanArchived(p, true);
                                  } else if (value == 'restore') {
                                    _setPlanArchived(p, false);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: _showArchived ? 'restore' : 'archive',
                                    child: Text(
                                      _showArchived
                                          ? context.l10n.planRestoreActive
                                          : context.l10n.planArchive,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _hint(String text) {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(20),
        color: palette.panel,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context
            .yoursText(YoursTextRole.body)
            .copyWith(
              color: palette.muted,
              fontSize: 14,
            ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Swipe-to-Reveal Edit/Delete (custom, no package dependency)
// ═══════════════════════════════════════════════════════════════════════════════
