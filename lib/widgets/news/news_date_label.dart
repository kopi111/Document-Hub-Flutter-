String relativePublishedLabel(DateTime publishedAt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final delta = reference.difference(publishedAt);
  if (delta.isNegative) return _absoluteLabel(publishedAt);
  if (delta.inMinutes < 1) return 'just now';
  if (delta.inMinutes < 60) {
    final minutes = delta.inMinutes;
    return '${minutes}m ago';
  }
  if (delta.inHours < 24) {
    return '${delta.inHours}h ago';
  }
  if (_isYesterday(publishedAt, reference)) return 'yesterday';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  return _absoluteLabel(publishedAt);
}

String absolutePublishedLabel(DateTime publishedAt) {
  return _absoluteLabel(publishedAt);
}

bool _isYesterday(DateTime publishedAt, DateTime now) {
  final published = DateTime(publishedAt.year, publishedAt.month, publishedAt.day);
  final today = DateTime(now.year, now.month, now.day);
  return today.difference(published).inDays == 1;
}

String _absoluteLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
