# Repository Usage Examples

This document contains non-runtime snippets that used to live in `lib/repository/usage_examples.dart`.

## Watching Projects

```dart
final projectsAsync = ref.watch(
  projectsPaginatedProvider(const ProjectPaginationParams(page: 1, limit: 100)),
);
```

## Adding a Project

```dart
final notifier = ref.read(projectsProvider.notifier);
await notifier.addProject(
  ProjectModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: 'New Project',
    progress: 0.0,
    tasks: const [],
    status: 'In Progress',
  ),
);
```

## Updating Progress

```dart
await ref.read(projectsProvider.notifier).updateProgress(projectId, 0.6);
```

## Deleting a Project

```dart
await ref.read(projectsProvider.notifier).deleteProject(projectId);
```

## Notes

- Keep example snippets in docs or `example/`, not under runtime `lib/` source.
- Runtime source should only contain code used by the app/package.
