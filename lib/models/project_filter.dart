/// This immutable class encapsulates all filtering criteria that can be applied
/// to project collections. All fields are optional and null values indicate no filtering
/// on that criterion.
///
/// Used by [filteredProjectsProvider] family provider for client-side filtering.
class ProjectFilter {
  /// Optional status to filter projects by their current status.
  final String? status;

  /// Optional start date to filter projects created on or after this date.
  final DateTime? startDate;

  /// Optional end date to filter projects created on or before this date.
  final DateTime? endDate;

  /// Optional priority to filter projects by their priority level.
  final String? priority;

  /// Optional list of tags to filter projects that contain any of these tags.
  final List<String>? tags;

  /// Optional search query to filter projects by name, description, or tags (case-insensitive substring match).
  final String? searchQuery;

  const ProjectFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.priority,
    this.tags,
    this.searchQuery,
  });

  /// Creates a copy of this filter with optionally updated fields.
  /// Null values in parameters preserve the current values.
  ProjectFilter copyWith({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? priority,
    List<String>? tags,
    String? searchQuery,
  }) {
    return ProjectFilter(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Returns an empty filter with all criteria set to null (no filtering).
  ProjectFilter get empty => const ProjectFilter();
}