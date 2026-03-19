import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  static String formatTime(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  static String timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }
}
