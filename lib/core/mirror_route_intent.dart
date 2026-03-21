class MirrorRouteIntent {
  const MirrorRouteIntent({
    required this.projectId,
    required this.taskId,
  });

  final String projectId;
  final String taskId;
}

MirrorRouteIntent? tryParseMirrorRouteIntent(String routeName) {
  final normalized = routeName.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return null;
  }

  final segments = uri.pathSegments;
  if (segments.length != 3 || segments.first != 'mirror') {
    return null;
  }

  final projectId = segments[1].trim();
  final taskId = segments[2].trim();
  if (projectId.isEmpty || taskId.isEmpty) {
    return null;
  }

  return MirrorRouteIntent(
    projectId: projectId,
    taskId: taskId,
  );
}

bool isMirrorRouteIntent(String routeName) {
  return tryParseMirrorRouteIntent(routeName) != null;
}
