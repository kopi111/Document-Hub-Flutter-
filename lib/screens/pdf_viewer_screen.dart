import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../models/document.dart';

class PdfViewerScreen extends StatefulWidget {
  final PolicyDocument document;

  const PdfViewerScreen({super.key, required this.document});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final FlutterTts _tts = FlutterTts();
  bool _hasError = false;
  bool _isReading = false;
  bool _isPaused = false;
  bool _isExtracting = false;
  String _extractedText = '';
  double _speechRate = 0.5;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      setState(() {
        _isReading = false;
        _isPaused = false;
      });
    });
  }

  Future<void> _extractAndRead() async {
    if (_isReading && !_isPaused) {
      // Pause
      await _tts.pause();
      setState(() => _isPaused = true);
      return;
    }

    if (_isPaused) {
      // Resume
      // flutter_tts doesn't support resume on all platforms, so we restart
      await _tts.speak(_extractedText);
      setState(() => _isPaused = false);
      return;
    }

    // Start fresh - extract text and read
    setState(() => _isExtracting = true);

    try {
      final response = await http.get(Uri.parse(widget.document.downloadUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final pdfDoc = pdf.PdfDocument(inputBytes: bytes);
        final textExtractor = pdf.PdfTextExtractor(pdfDoc);

        final buffer = StringBuffer();
        _totalPages = pdfDoc.pages.count;

        for (int i = 0; i < pdfDoc.pages.count; i++) {
          final pageText = textExtractor.extractText(startPageIndex: i);
          if (pageText.isNotEmpty) {
            buffer.writeln(pageText);
          }
        }

        pdfDoc.dispose();
        _extractedText = buffer.toString().trim();

        if (_extractedText.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No readable text found in this PDF'),
              ),
            );
          }
          setState(() => _isExtracting = false);
          return;
        }

        setState(() {
          _isExtracting = false;
          _isReading = true;
          _isPaused = false;
        });

        await _tts.speak(_extractedText);
      } else {
        setState(() => _isExtracting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download PDF for reading')),
          );
        }
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _stopReading() async {
    await _tts.stop();
    setState(() {
      _isReading = false;
      _isPaused = false;
    });
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        double tempRate = _speechRate;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Reading Speed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: _speedLabel(tempRate),
                    onChanged: (val) {
                      setDialogState(() => tempRate = val);
                    },
                  ),
                  Text(_speedLabel(tempRate),
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() => _speechRate = tempRate);
                    _tts.setSpeechRate(tempRate);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _speedLabel(double rate) {
    if (rate <= 0.25) return 'Slow';
    if (rate <= 0.5) return 'Normal';
    if (rate <= 0.75) return 'Fast';
    return 'Very Fast';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.displayName,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () =>
                _controller.zoomLevel = _controller.zoomLevel + 0.25,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              if (_controller.zoomLevel > 0.5) {
                _controller.zoomLevel = _controller.zoomLevel - 0.25;
              }
            },
          ),
        ],
      ),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load PDF'),
                  const SizedBox(height: 8),
                  Text(
                    widget.document.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _hasError = false),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : widget.document.name.endsWith('.pdf')
              ? SfPdfViewer.network(
                  widget.document.downloadUrl,
                  controller: _controller,
                  onDocumentLoadFailed: (details) {
                    setState(() => _hasError = true);
                  },
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                          'This document format is not supported for preview.'),
                    ],
                  ),
                ),
      // Read aloud controls at bottom
      bottomNavigationBar: widget.document.name.endsWith('.pdf')
          ? Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Play/Pause button
                  _isExtracting
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton.filled(
                          onPressed: _extractAndRead,
                          icon: Icon(
                            _isReading && !_isPaused
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          tooltip: _isReading && !_isPaused
                              ? 'Pause'
                              : 'Read Aloud',
                        ),
                  const SizedBox(width: 8),
                  // Stop button
                  if (_isReading || _isPaused)
                    IconButton.outlined(
                      onPressed: _stopReading,
                      icon: const Icon(Icons.stop),
                      tooltip: 'Stop',
                    ),
                  const SizedBox(width: 8),
                  // Status text
                  Expanded(
                    child: Text(
                      _isExtracting
                          ? 'Extracting text...'
                          : _isReading && !_isPaused
                              ? 'Reading aloud...'
                              : _isPaused
                                  ? 'Paused'
                                  : 'Tap play to read aloud',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  // Speed button
                  IconButton(
                    onPressed: _showSpeedDialog,
                    icon: const Icon(Icons.speed),
                    tooltip: 'Reading Speed',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }
}
