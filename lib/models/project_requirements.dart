/// Model for project requirements
class ProjectRequirements {
  final List<String> software;
  final List<String> hardware;

  const ProjectRequirements({
    this.software = const [],
    this.hardware = const [],
  });

  factory ProjectRequirements.fromJson(Map<String, dynamic> json) {
    return ProjectRequirements(
      software: (json['software'] as List<dynamic>?)?.cast<String>() ?? const [],
      hardware: (json['hardware'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'software': software,
      'hardware': hardware,
    };
  }

  bool get isEmpty => software.isEmpty && hardware.isEmpty;
  bool get isNotEmpty => !isEmpty;
}