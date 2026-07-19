String friendlyDatabaseMessage(Object error) {
  final message = error.toString().toLowerCase();

  if (message.contains('permission denied')) {
    return 'Your account does not currently have permission to access this information.';
  }

  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection') ||
      message.contains('timeout')) {
    return 'Check your internet connection and try again.';
  }

  return 'We could not load your information. Please try again.';
}

String friendlyHistoryMessage(Object error) {
  final message = error.toString().toLowerCase();

  if (message.contains('permission denied') ||
      message.contains('permission-denied')) {
    return 'Your account cannot access this history.';
  }

  if (message.contains('not signed in') ||
      message.contains('not authenticated')) {
    return 'Please sign in again to view your saved history.';
  }

  if (message.contains('format') ||
      message.contains('subtype') ||
      message.contains('cast')) {
    return 'Some saved history data could not be read.';
  }

  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('timeout') ||
      message.contains('connection')) {
    return 'Check your internet connection and try again.';
  }

  return 'We could not access your saved activity. Please try again.';
}
