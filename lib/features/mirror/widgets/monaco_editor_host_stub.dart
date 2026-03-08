import 'package:flutter/material.dart';

class MonacoEditorHost extends StatefulWidget {
  const MonacoEditorHost({
    super.key,
    required this.code,
    required this.language,
    required this.theme,
    required this.onChanged,
  });

  final String code;
  final String language;
  final String theme;
  final ValueChanged<String> onChanged;

  @override
  State<MonacoEditorHost> createState() => _MonacoEditorHostState();
}

class _MonacoEditorHostState extends State<MonacoEditorHost> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(covariant MonacoEditorHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code && _controller.text != widget.code) {
      _controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.theme == 'vs-dark'
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Editor (${widget.language})',
        ),
        style: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 14,
          color: widget.theme == 'vs-dark' ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
