class MirrorTemplate {
  const MirrorTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.seedContent,
    this.tags = const <String>[],
    this.iconName = '',
  });

  final String id;
  final String title;
  final String description;
  final String seedContent;
  final List<String> tags;
  final String iconName;
}
