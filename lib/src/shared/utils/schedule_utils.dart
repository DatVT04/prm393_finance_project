import 'package:prm393_finance_project/src/core/models/schedule_model.dart';

class ScheduleUtils {
  /// Calculates the next valid run date based on the schedule's repeat type and current time.
  static DateTime calculateNextValidDate(ScheduleModel schedule, DateTime now) {
    DateTime current = schedule.nextRun ?? schedule.startDate;
    
    // If it's already in the future, just return it
    if (current.isAfter(now)) return current;

    switch (schedule.repeatType.toUpperCase()) {
      case 'DAILY':
        while (!current.isAfter(now)) {
          current = current.add(const Duration(days: 1));
        }
        break;
      case 'WEEKLY':
        while (!current.isAfter(now)) {
          current = current.add(const Duration(days: 7));
        }
        break;
      case 'MONTHLY':
        while (!current.isAfter(now)) {
          current = DateTime(current.year, current.month + 1, current.day, current.hour, current.minute);
        }
        break;
      case 'YEARLY':
        while (!current.isAfter(now)) {
          current = DateTime(current.year + 1, current.month, current.day, current.hour, current.minute);
        }
        break;
      case 'CUSTOM':
        if (schedule.repeatConfig != null && schedule.repeatConfig!.isNotEmpty) {
          try {
            final dates = schedule.repeatConfig!.split(',').map((d) => DateTime.parse(d)).toList();
            dates.sort((a, b) => a.compareTo(b));
            // Find the first date that is after now
            final next = dates.where((d) => d.isAfter(now)).toList();
            if (next.isNotEmpty) {
              current = next.first;
            } else {
              // If no custom dates are in the future, default to tomorrow
              current = DateTime(now.year, now.month, now.day + 1, current.hour, current.minute);
            }
          } catch (e) {
            current = DateTime(now.year, now.month, now.day + 1, current.hour, current.minute);
          }
        } else {
          current = DateTime(now.year, now.month, now.day + 1, current.hour, current.minute);
        }
        break;
      case 'NONE':
      default:
        // For one-time schedules in the past, move to tomorrow
        current = DateTime(now.year, now.month, now.day + 1, current.hour, current.minute);
        break;
    }
    return current;
  }
}
