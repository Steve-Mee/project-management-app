// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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
  late final String _viewType;
  late final html.IFrameElement _iframe;
  late final StreamSubscription<html.MessageEvent> _messageSubscription;

  @override
  void initState() {
    super.initState();
    _viewType = 'mirror-monaco-${DateTime.now().microsecondsSinceEpoch}';
    _iframe = html.IFrameElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..srcdoc = _buildMonacoPage(
        code: widget.code,
        language: widget.language,
        theme: widget.theme,
      );

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    _messageSubscription = html.window.onMessage.listen((html.MessageEvent event) {
      final data = event.data;
      if (data is! Map) {
        return;
      }
      if (data['source'] != 'mirror-monaco') {
        return;
      }
      final value = data['value'];
      if (value is String) {
        widget.onChanged(value);
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MonacoEditorHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code ||
        oldWidget.language != widget.language ||
        oldWidget.theme != widget.theme) {
      _iframe.srcdoc = _buildMonacoPage(
        code: widget.code,
        language: widget.language,
        theme: widget.theme,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

String _buildMonacoPage({
  required String code,
  required String language,
  required String theme,
}) {
  final encodedCode = jsonEncode(code);
  final encodedLanguage = jsonEncode(language);
  final encodedTheme = jsonEncode(theme);

  return '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      html, body, #editor { height: 100%; margin: 0; padding: 0; overflow: hidden; }
      body { background: ${theme == 'vs-dark' ? '#1E1E1E' : '#FFFFFF'}; }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.52.2/min/vs/loader.min.js"></script>
  </head>
  <body>
    <div id="editor"></div>
    <script>
      const initialCode = $encodedCode;
      const language = $encodedLanguage;
      const theme = $encodedTheme;
      require.config({ paths: { vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.52.2/min/vs' } });
      require(['vs/editor/editor.main'], function () {
        const editor = monaco.editor.create(document.getElementById('editor'), {
          value: initialCode,
          language: language,
          theme: theme,
          automaticLayout: true,
          minimap: { enabled: true },
          fontSize: 14,
        });

        editor.onDidChangeModelContent(function() {
          parent.postMessage({ source: 'mirror-monaco', value: editor.getValue() }, '*');
        });
      });
    </script>
  </body>
</html>
''';
}
