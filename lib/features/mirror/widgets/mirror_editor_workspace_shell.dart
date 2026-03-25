import 'package:flutter/material.dart';

class MirrorEditorWorkspaceShell extends StatelessWidget {
  const MirrorEditorWorkspaceShell({
    super.key,
    required this.fileExplorer,
    required this.editorAndTerminal,
  });

  final Widget fileExplorer;
  final Widget editorAndTerminal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isCompact = constraints.maxWidth < 900;

        if (isCompact) {
          return Column(
            children: <Widget>[
              SizedBox(height: 180, child: fileExplorer),
              const Divider(height: 1),
              Expanded(child: editorAndTerminal),
            ],
          );
        }

        return Row(
          children: <Widget>[
            SizedBox(width: 280, child: fileExplorer),
            const VerticalDivider(width: 1),
            Expanded(child: editorAndTerminal),
          ],
        );
      },
    );
  }
}

class MirrorEditorFileExplorer extends StatelessWidget {
  const MirrorEditorFileExplorer({
    super.key,
    required this.files,
    required this.selectedFile,
    required this.filesLabel,
    required this.iconForFile,
    required this.onFileSelected,
  });

  final Map<String, String> files;
  final String selectedFile;
  final String filesLabel;
  final IconData Function(String path) iconForFile;
  final ValueChanged<String> onFileSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Text(
            filesLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: files.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final filePath = files.keys.elementAt(index);
              final isActive = filePath == selectedFile;

              return ListTile(
                dense: true,
                selected: isActive,
                leading: Icon(iconForFile(filePath), size: 18),
                title: Text(
                  filePath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onFileSelected(filePath),
              );
            },
          ),
        ),
      ],
    );
  }
}