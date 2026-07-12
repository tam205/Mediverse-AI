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
