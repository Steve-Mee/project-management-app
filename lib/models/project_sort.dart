enum ProjectSort {
  name,
  progress,
  priority,
}

extension ProjectSortX on ProjectSort {
  String get label {
    switch (this) {
      case ProjectSort.name:
        return 'Naam';
      case ProjectSort.progress:
        return 'Voortgang';
      case ProjectSort.priority:
        return 'Prioriteit';
    }
  }
}
