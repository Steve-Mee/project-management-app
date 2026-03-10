// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
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

  factory MirrorTemplate.fromMap(Map<String, dynamic> row) {
    final templateKey = _readString(
      row,
      const <String>['template_key', 'templateKey', 'key'],
    );
    final rawId = (row['id'] ?? '').toString().trim();
    final id = templateKey.isNotEmpty ? templateKey : rawId;
    final tagsRaw = row['tags'];
    final tags = tagsRaw is List
        ? tagsRaw
            .map((dynamic tag) => tag.toString())
            .where((String tag) => tag.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    return MirrorTemplate(
      id: id,
      title: _readString(
        row,
        const <String>['title'],
        fallback: 'Untitled template',
      ),
      description: _readString(row, const <String>['description']),
      seedContent: _readString(
        row,
        const <String>['seed_content', 'seedContent', 'content'],
      ),
      tags: tags,
      iconName: _readString(
        row,
        const <String>['icon_name', 'iconName', 'icon'],
        fallback: templateKey,
      ),
    );
  }

  static String _readString(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) {
        continue;
      }
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return fallback;
  }
}
