import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_finance_project/src/core/models/schedule_model.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';
import 'package:prm393_finance_project/src/shared/utils/currency_formatter.dart';

import 'add_edit_schedule_screen.dart';

class SchedulerScreen extends ConsumerWidget {
  const SchedulerScreen({super.key});

  Future<void> _disableSchedule(WidgetRef ref, BuildContext context, ScheduleModel schedule) async {
    try {
      await ref.read(apiClientProvider).disableSchedule(schedule.id!);
      refreshSchedules(ref);
      if (!context.mounted) return;
      ToastNotification.show(context, 'schedule_disabled_success'.tr());
    } catch (e) {
      if (!context.mounted) return;
      ToastNotification.show(context, 'Error: $e', status: ToastStatus.error);
    }
  }

  Future<void> _enableSchedule(WidgetRef ref, BuildContext context, ScheduleModel schedule) async {
    try {
      await ref.read(apiClientProvider).enableSchedule(schedule.id!);
      refreshSchedules(ref);
      if (!context.mounted) return;
      ToastNotification.show(context, 'schedule_enabled_success'.tr());
    } catch (e) {
      if (!context.mounted) return;
      ToastNotification.show(context, 'Error: $e', status: ToastStatus.error);
    }
  }

  Future<void> _deleteSchedule(WidgetRef ref, BuildContext context, ScheduleModel schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text('delete_schedule_confirm'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Text('delete_schedule_body'.tr(), style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('delete'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(apiClientProvider).deleteSchedule(schedule.id!);
      refreshSchedules(ref);
      if (!context.mounted) return;
      ToastNotification.show(context, 'schedule_deleted_success'.tr(), status: ToastStatus.warning);
    } catch (e) {
      if (!context.mounted) return;
      ToastNotification.show(context, 'Error: $e', status: ToastStatus.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('scheduler_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: schedulesAsync.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_repeat,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'no_scheduled_transactions'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'no_scheduled_transactions'.tr(), 
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: schedules.length,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _buildScheduleCard(context, ref, schedule, theme);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('${'error_loading_schedules'.tr()}$err', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditScheduleScreen(),
            ),
          );
          if (created == true) {
            refreshSchedules(ref);
          }
        },
        icon: const Icon(Icons.add),
        label: Text('add_schedule'.tr()),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, WidgetRef ref, ScheduleModel schedule, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: schedule.isActive ? theme.colorScheme.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditScheduleScreen(scheduleToEdit: schedule),
              ),
            );
            if (updated == true) {
              refreshSchedules(ref);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: schedule.isActive ? theme.colorScheme.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        schedule.isActive ? 'schedule_status_active'.tr() : 'schedule_status_inactive'.tr(),
                        style: TextStyle(
                          color: schedule.isActive ? theme.colorScheme.primary : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(context, schedule.amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title and Repeat Type
                Text(
                  schedule.note != null && schedule.note!.isNotEmpty ? schedule.note! : 'No Note',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${'repeat_type'.tr()}: ${('repeat_${schedule.repeatType.toLowerCase()}').tr()}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                if (schedule.nextRun != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_available, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${'next_run'.tr()}: ${DateFormat('dd/MM/yyyy HH:mm').format(schedule.nextRun!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (schedule.isActive)
                      TextButton.icon(
                        onPressed: () => _disableSchedule(ref, context, schedule),
                        icon: const Icon(Icons.pause_circle_outline, size: 18),
                        label: Text('schedule_disable'.tr()),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _enableSchedule(ref, context, schedule),
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: Text('schedule_enable'.tr()),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteSchedule(ref, context, schedule),
                      tooltip: 'delete'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
