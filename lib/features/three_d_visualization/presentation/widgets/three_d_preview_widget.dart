
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThreeDPreviewWidget extends StatefulWidget {
  const ThreeDPreviewWidget({
    super.key,
    required this.glbUrl,
    this.height = 220,
    this.initialBackgroundDark = false,
    this.showControls = true,
  });

  final String glbUrl;
  final double height;
  final bool initialBackgroundDark;
  final bool showControls;

  @override
  State<ThreeDPreviewWidget> createState() => _ThreeDPreviewWidgetState();
}

class _ThreeDPreviewWidgetState extends State<ThreeDPreviewWidget> {
  bool _autoRotate = true;
  bool _zoomEnabled = true;
  bool _darkBackground = false;

  @override
  void initState() {
    super.initState();
    _darkBackground = widget.initialBackgroundDark;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _darkBackground ? Colors.black : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showControls)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Rotate'),
                  selected: _autoRotate,
                  onSelected: (selected) {
                    setState(() {
                      _autoRotate = selected;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Zoom'),
                  selected: _zoomEnabled,
                  onSelected: (selected) {
                    setState(() {
                      _zoomEnabled = selected;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Dark BG'),
                  selected: _darkBackground,
                  onSelected: (selected) {
                    setState(() {
                      _darkBackground = selected;
                    });
                  },
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: widget.height,
            color: backgroundColor,
            child: kIsWeb
                ? _FlutterGlWebFallback(
                    glbUrl: widget.glbUrl,
                    zoomEnabled: _zoomEnabled,
                    autoRotate: _autoRotate,
                    darkBackground: _darkBackground,
                  )
                : ModelViewer(
                    src: widget.glbUrl,
                    alt: '3D preview',
                    ar: false,
                    autoRotate: _autoRotate,
                    autoPlay: true,
                    cameraControls: true,
                    disableZoom: !_zoomEnabled,
                    disablePan: false,
                    backgroundColor: backgroundColor,
                    loading: Loading.eager,
                  ),
          ),
        ),
      ],
    );
  }
}

class _FlutterGlWebFallback extends StatefulWidget {
  const _FlutterGlWebFallback({
    required this.glbUrl,
    required this.zoomEnabled,
    required this.autoRotate,
    required this.darkBackground,
  });

  final String glbUrl;
  final bool zoomEnabled;
  final bool autoRotate;
  final bool darkBackground;

  @override
  State<_FlutterGlWebFallback> createState() => _FlutterGlWebFallbackState();
}

class _FlutterGlWebFallbackState extends State<_FlutterGlWebFallback> {
  final FlutterGlPlugin _glPlugin = FlutterGlPlugin();

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.darkBackground ? Colors.black : Colors.white;
    final fgColor = widget.darkBackground ? Colors.white : Colors.black87;

    Widget content = Container(
      color: bgColor,
      child: Center(
        child: AnimatedRotation(
          turns: widget.autoRotate ? 0.03 : 0,
          duration: const Duration(milliseconds: 900),
          child: Icon(
            Icons.view_in_ar_outlined,
            size: 56,
            color: fgColor,
          ),
        ),
      ),
    );

    if (widget.zoomEnabled) {
      content = InteractiveViewer(
        minScale: 0.7,
        maxScale: 3.5,
        child: content,
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.darkBackground
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Web fallback active (flutter_gl): ${_glPlugin.runtimeType}\\n${widget.glbUrl}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: fgColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
