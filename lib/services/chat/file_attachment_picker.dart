// INTEGRATION: In chat_thread_screen.dart composer, hold a FileAttachmentPicker and call:
//   final att = await _picker.pickFile();
//   if (att != null) controller.sendAttachment(att, type: MessageType.file);
// Replace StubFileAttachmentPicker with a concrete impl backed by
// `file_picker: ^8.x` (add to pubspec.yaml) once native plugins are enabled.

import '../../models/chat/chat_attachment.dart';

/// Contract for picking a file from device storage.
///
/// Returns null when the user cancels. Implementations are injected so the
/// composer compiles and tests without native plugin binaries.
abstract class FileAttachmentPicker {
  Future<ChatAttachment?> pickFile();
}

/// Compile-safe stand-in that resolves immediately with a sample PDF attachment.
/// Replace with a `file_picker`-backed implementation in production.
class StubFileAttachmentPicker implements FileAttachmentPicker {
  const StubFileAttachmentPicker();

  @override
  Future<ChatAttachment?> pickFile() async {
    return const ChatAttachment(
      url: 'local://sample-document.pdf',
      name: 'sample-document.pdf',
      sizeBytes: 2457600,
      mimeType: 'application/pdf',
    );
  }
}
