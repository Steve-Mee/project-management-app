import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_filter.freezed.dart';
part 'project_filter.g.dart';

/// This immutable class encapsulates all filtering criteria that can be applied
/// to project collections. All fields are optional and null values indicate no filtering
/// on that criterion.
///
/// Used by [filteredProjectsProvider] family provider for client-side filtering.
@freezed
abstract class ProjectFilter with _$ProjectFilter {
  const ProjectFilter._();

  const factory ProjectFilter({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? priority,
    List<String>? tags,
    String? searchQuery,
  }) = _ProjectFilter;

  factory ProjectFilter.fromJson(Map<String, dynamic> json) =>
      _$ProjectFilterFromJson(json);

  /// Returns an empty filter with all criteria set to null (no filtering).
  ProjectFilter get empty => const ProjectFilter();
}
