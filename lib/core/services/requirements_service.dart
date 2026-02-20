import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/models/project_requirements.dart';

/// Service for fetching project requirements from external APIs
class RequirementsService {
  static const String _baseUrl = 'https://api.example.com'; // Replace with actual API

  /// Fetch requirements for a project by category
  Future<ProjectRequirements> fetchRequirements(String projectCategory) async {
    try {
      final url = Uri.parse('$_baseUrl/requirements?category=$projectCategory');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProjectRequirements.fromJson(data);
      } else {
        AppLogger.instance.w('Failed to fetch requirements: ${response.statusCode}');
        return const ProjectRequirements();
      }
    } catch (e) {
      AppLogger.instance.e('Error fetching requirements', error: e);
      return const ProjectRequirements();
    }
  }

  /// Parse requirements from a string format like "software: 'Flutter SDK, VS Code'; hardware: 'Tools list'"
  ProjectRequirements parseRequirementsString(String requirementsString) {
    final software = <String>[];
    final hardware = <String>[];

    // Split by semicolons to get different requirement types
    final parts = requirementsString.split(';');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('software:')) {
        final softwareStr = trimmed.substring('software:'.length).trim();
        // Remove quotes if present
        final cleanStr = softwareStr.replaceAll("'", '').replaceAll('"', '');
        software.addAll(cleanStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      } else if (trimmed.startsWith('hardware:')) {
        final hardwareStr = trimmed.substring('hardware:'.length).trim();
        // Remove quotes if present
        final cleanStr = hardwareStr.replaceAll("'", '').replaceAll('"', '');
        hardware.addAll(cleanStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      }
    }

    return ProjectRequirements(
      software: software,
      hardware: hardware,
    );
  }
}