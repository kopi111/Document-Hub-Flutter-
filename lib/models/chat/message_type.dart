/// The kind of content a [ChatMessage] carries. Drives which bubble widget
/// renders it. Defaults to [text] for backward compatibility with messages
/// that predate rich content.
enum MessageType { text, voice, image, file, location, system }

/// Wire <-> enum mapping kept beside the enum so every serializer agrees.
extension MessageTypeWire on MessageType {
  String get wire {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.voice:
        return 'voice';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.location:
        return 'location';
      case MessageType.system:
        return 'system';
    }
  }

  static MessageType fromWire(String? value) {
    switch (value) {
      case 'voice':
        return MessageType.voice;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}
