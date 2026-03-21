import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _monacoAssetBasePath = '/assets/assets/monaco/vs';

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
  InAppWebViewController? _webViewController;
  late TextEditingController _fallbackController;
  String _lastDesktopCode = '';
  bool _allowDesktopLimitedEditor = false;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  bool get _canUseInAppWebView => InAppWebViewPlatform.instance != null;

  @override
  void initState() {
    super.initState();
    _fallbackController = TextEditingController(text: widget.code);
    _lastDesktopCode = widget.code;
  }

  @override
  void dispose() {
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MonacoEditorHost oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isDesktop) {
      if (oldWidget.code != widget.code &&
          _fallbackController.text != widget.code) {
        _fallbackController.value = TextEditingValue(
          text: widget.code,
          selection: TextSelection.collapsed(offset: widget.code.length),
        );
      }
      return;
    }

    if (oldWidget.code != widget.code && widget.code != _lastDesktopCode) {
      _lastDesktopCode = widget.code;
      _setMonacoValue(widget.code);
    }

    if (oldWidget.language != widget.language ||
        oldWidget.theme != widget.theme) {
      _reloadDesktopEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) {
      return _buildMobileFallback();
    }

    if (!_canUseInAppWebView) {
      if (_allowDesktopLimitedEditor) {
        return _buildDesktopLimitedFallback();
      }
      return _buildDesktopDegradedState();
    }

    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _buildMonacoPage(
          code: widget.code,
          language: widget.language,
          theme: widget.theme,
        ),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: false,
        supportZoom: false,
      ),
      onWebViewCreated: (InAppWebViewController controller) {
        _webViewController = controller;
        controller.addJavaScriptHandler(
          handlerName: 'onCodeChanged',
          callback: (List<dynamic> args) {
            final value = args.isNotEmpty ? args.first?.toString() ?? '' : '';
            _lastDesktopCode = value;
            widget.onChanged(value);
            return null;
          },
        );
      },
      onLoadStop: (_, __) async {
        await _setMonacoValue(widget.code);
      },
    );
  }

  Widget _buildMobileFallback() {
    return Container(
      color: widget.theme == 'vs-dark'
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _fallbackController,
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

  Widget _buildDesktopDegradedState() {
    final isDark = widget.theme == 'vs-dark';
    final warningColor = isDark ? const Color(0xFF2A2010) : const Color(0xFFFFF7E6);
    final warningBorder = isDark ? const Color(0xFFD6A64B) : const Color(0xFFDB9A00);

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Studio editor unavailable on this desktop runtime',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Mirror can continue in a limited text editor. Syntax features and studio-level safeguards may be reduced until Monaco is available again.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: warningBorder),
                ),
                child: const Text(
                  'Recommended: retry initialization first. Continue in limited mode only if needed.',
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry editor initialization'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _allowDesktopLimitedEditor = true;
                      });
                    },
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('Continue in limited editor'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLimitedFallback() {
    final isDark = widget.theme == 'vs-dark';

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A2B15) : const Color(0xFFFFF4D6),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFFB4883A) : const Color(0xFFDB9A00),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Limited desktop editor mode active. Monaco features are temporarily unavailable.',
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _allowDesktopLimitedEditor = false;
                    });
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore studio editor'),
                ),
              ],
            ),
          ),
          Expanded(child: _buildMobileFallback()),
        ],
      ),
    );
  }

  Future<void> _setMonacoValue(String code) async {
    final controller = _webViewController;
    if (controller == null) {
      return;
    }

    final encoded = jsonEncode(code);
    await controller.evaluateJavascript(
      source: 'window.__setMirrorCode && window.__setMirrorCode($encoded);',
    );
  }

  Future<void> _reloadDesktopEditor() async {
    final controller = _webViewController;
    if (controller == null) {
      return;
    }

    await controller.loadData(
      data: _buildMonacoPage(
        code: widget.code,
        language: widget.language,
        theme: widget.theme,
      ),
    );
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
    <script src="$_monacoAssetBasePath/loader.js"></script>
  </head>
  <body>
    <div id="editor"></div>
    <script>
      const initialCode = $encodedCode;
      const language = $encodedLanguage;
      const theme = $encodedTheme;
      require.config({ paths: { vs: '$_monacoAssetBasePath' } });
      require(['vs/editor/editor.main'], function () {
        const editor = monaco.editor.create(document.getElementById('editor'), {
          value: initialCode,
          language: language,
          theme: theme,
          automaticLayout: true,
          minimap: { enabled: true },
          fontSize: 14,
        });

        window.__setMirrorCode = function(value) {
          if (typeof value !== 'string') {
            return;
          }
          if (editor.getValue() === value) {
            return;
          }
          editor.setValue(value);
        };

        editor.onDidChangeModelContent(function() {
          const value = editor.getValue();
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('onCodeChanged', value);
          }
        });
      });
    </script>
  </body>
</html>
''';
}
