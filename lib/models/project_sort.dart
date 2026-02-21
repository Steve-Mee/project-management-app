enum ProjectSort {
  name,
  progress,
  priority,
  createdDate,
  status,
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
      case ProjectSort.createdDate:
        return 'Datum';
      case ProjectSort.status:
        return 'Status';
    }
  }
}
