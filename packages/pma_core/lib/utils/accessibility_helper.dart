import 'package:flutter/material.dart';

/// Reusable accessibility helpers for TalkBack and VoiceOver.
///
/// This file centralizes common semantics patterns so widgets stay readable and
/// consistent across the app.
///
/// Quick usage examples:
///
/// ```dart
/// // 1) Add semantics to any widget
/// Text(project.name).withSemantics(
///   'Project name ${project.name}',
///   hint: 'Double tap to open project details',
/// );
///
/// // 2) Build a labeled icon button
/// labeledIconButton(
///   icon: Icons.delete,
///   label: AccessibilityLabels.deleteProject,
///   onPressed: onDelete,
/// );
///
/// // 3) Wrap a list for better screen reader navigation
/// wrapSemanticList(
///   label: 'Projects list',
///   itemCount: projects.length,
///   child: ListView.builder(...),
/// );
/// ```

/// Adds semantic metadata to any widget with a concise extension API.
extension AccessibilityWidgetExtension on Widget {
	/// Wraps the widget in [Semantics] with an accessible [label] and optional
	/// [hint] or [value].
	Widget withSemantics(
		String label, {
		String? hint,
		String? value,
	}) {
		return Semantics(
			container: true,
			label: label,
			hint: hint,
			value: value,
			child: this,
		);
	}
}

/// Common semantic labels used across project management features.
///
/// Keep labels action-oriented and specific so screen readers announce clear
/// intent.
class AccessibilityLabels {
	static const String deleteProject = 'Delete project';
	static const String editProjectProgress = 'Edit project progress';
	static const String openProjectDetails = 'Open project details';
	static const String addNewTask = 'Add new task';
	static const String addNewProject = 'Add new project';
	static const String saveChanges = 'Save changes';
	static const String cancelAction = 'Cancel';
	static const String retryAction = 'Retry';
	static const String projectsList = 'Projects list';
	static const String projectTasksList = 'Project tasks list';

	const AccessibilityLabels._();
}

/// Creates an icon with semantics.
///
/// Set [decorative] to true for visual-only icons so they are ignored by
/// screen readers.
Widget labeledIcon({
	required IconData icon,
	required String label,
	String? hint,
	Color? color,
	double size = 24,
	bool decorative = false,
}) {
	final iconWidget = Icon(icon, color: color, size: size);
	if (decorative) {
		return ExcludeSemantics(child: iconWidget);
	}

	return Semantics(
		image: true,
		label: label,
		hint: hint,
		child: iconWidget,
	);
}

/// Creates an [IconButton] with consistent semantics and tooltip text.
Widget labeledIconButton({
	required IconData icon,
	required String label,
	required VoidCallback? onPressed,
	String? hint,
	Color? color,
	double size = 24,
	Key? key,
}) {
	return Semantics(
		button: true,
		enabled: onPressed != null,
		label: label,
		hint: hint,
		child: IconButton(
			key: key,
			tooltip: label,
			onPressed: onPressed,
			icon: Icon(icon, color: color, size: size),
		),
	);
}

/// Creates an [ElevatedButton] with semantics metadata.
Widget labeledElevatedButton({
	required String label,
	required VoidCallback? onPressed,
	String? hint,
	String? value,
	IconData? leadingIcon,
	Key? key,
}) {
	final child = leadingIcon == null
			? Text(label)
			: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(leadingIcon, size: 18),
						const SizedBox(width: 8),
						Text(label),
					],
				);

	return Semantics(
		button: true,
		enabled: onPressed != null,
		label: label,
		hint: hint,
		value: value,
		child: ElevatedButton(
			key: key,
			onPressed: onPressed,
			child: child,
		),
	);
}

/// Creates a [TextButton] with semantics metadata.
Widget labeledTextButton({
	required String label,
	required VoidCallback? onPressed,
	String? hint,
	String? value,
	IconData? leadingIcon,
	Key? key,
}) {
	final child = leadingIcon == null
			? Text(label)
			: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(leadingIcon, size: 18),
						const SizedBox(width: 8),
						Text(label),
					],
				);

	return Semantics(
		button: true,
		enabled: onPressed != null,
		label: label,
		hint: hint,
		value: value,
		child: TextButton(
			key: key,
			onPressed: onPressed,
			child: child,
		),
	);
}

/// Wraps scrolling lists so screen readers announce list context and size.
///
/// This improves orientation for users navigating long lists with TalkBack or
/// VoiceOver.
Widget wrapSemanticList({
	required String label,
	required Widget child,
	int? itemCount,
	String? hint,
}) {
	return Semantics(
		container: true,
		explicitChildNodes: true,
		label: label,
		hint: hint,
		value: itemCount == null ? null : '$itemCount items',
		child: child,
	);
}

