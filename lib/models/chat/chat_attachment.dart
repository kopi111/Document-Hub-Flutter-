/// Non-text payload riding on a [ChatMessage]: a voice note, image, or file.
/// Fields are deliberately superset — a voice note uses [durationMs] and
/// [waveform]; an image uses [width]/[height]; a file uses [name]/[sizeBytes].
class ChatAttachment {
  /// Where the binary lives. A remote URL once uploaded, or a local file path /
  /// blob URL while still pending send.
  final String url;

  /// Original file name, shown for file attachments.
  final String? name;

  /// Size in bytes, shown for file attachments.
  final int? sizeBytes;

  /// MIME type, e.g. `audio/m4a`, `image/jpeg`, `application/pdf`.
  final String? mimeType;

  /// Voice-note length in milliseconds.
  final int? durationMs;

  /// Normalised 0..1 amplitude bars for a voice-note waveform.
  final List<double>? waveform;

  /// Pixel dimensions for an image attachment, used to size the bubble before
  /// the image loads.
  final int? width;
  final int? height;

  const ChatAttachment({
    required this.url,
    this.name,
    this.sizeBytes,
    this.mimeType,
    this.durationMs,
    this.waveform,
    this.width,
    this.height,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        url: json['url'] as String,
        name: json['name'] as String?,
        sizeBytes: json['size_bytes'] as int?,
        mimeType: json['mime_type'] as String?,
        durationMs: json['duration_ms'] as int?,
        waveform: (json['waveform'] as List<dynamic>?)
            ?.map((v) => (v as num).toDouble())
            .toList(growable: false),
        width: json['width'] as int?,
        height: json['height'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        if (name != null) 'name': name,
        if (sizeBytes != null) 'size_bytes': sizeBytes,
        if (mimeType != null) 'mime_type': mimeType,
        if (durationMs != null) 'duration_ms': durationMs,
        if (waveform != null) 'waveform': waveform,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  /// Human-readable size, e.g. `2.4 MB`. Empty when [sizeBytes] is unknown.
  String get readableSize {
    final bytes = sizeBytes;
    if (bytes == null) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final rounded = unit == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$rounded ${units[unit]}';
  }
}
