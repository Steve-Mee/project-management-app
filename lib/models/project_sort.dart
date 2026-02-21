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
        return 'Name';
      case ProjectSort.progress:
        return 'Progress';
      case ProjectSort.priority:
        return 'Priority';
      case ProjectSort.createdDate:
        return 'Created';
      case ProjectSort.status:
        return 'Status';
    }
  }
}
