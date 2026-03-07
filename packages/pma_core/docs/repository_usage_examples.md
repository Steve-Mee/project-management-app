# Repository Usage Examples

This document contains non-runtime snippets that used to live in `lib/repository/usage_examples.dart`.

## Watching Projects

```dart
final projectsAsync = ref.watch(
  projectsPaginatedProvider(const ProjectPaginationParams(page: 1, limit: 100)),
);
```

Legacy alias (deprecated):

```dart
final projectsAsync = ref.watch(
  paginatedProjectsProvider(const ProjectPaginationParams(page: 1, limit: 100)),
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

## Testing Project Providers

```dart
final fakeRepository = FakeProjectRepository(seed: const [
  ProjectModel(id: 'p1', name: 'Alpha', progress: 0.2, status: 'In Progress'),
]);

final container = ProviderContainer(overrides: [
  projectRepositoryProvider.overrideWithValue(fakeRepository),
]);

final projects = await container.read(projectsProvider.future);
expect(projects.length, 1);
```

- `ProjectsNotifier.initialize()` is not part of the current API.
- Use provider overrides + `projectsProvider.future` to make tests deterministic.
