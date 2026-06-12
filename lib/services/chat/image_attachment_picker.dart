// INTEGRATION: Swap StubImageAttachmentPicker for a real implementation built on
// image_picker (^1.1.2, already in pubspec.yaml). See ImagePickerAttachmentPicker
// sketch below. Wire it into your DI / provider so the ChatComposerBar can call
// sendAttachment(att, type: MessageType.image) on the ChatThreadController.
//
// class ImagePickerAttachmentPicker implements ImageAttachmentPicker {
//   final _picker = ImagePicker();
//
//   @override
//   Future<ChatAttachment?> pickFromGallery() => _pick(ImageSource.gallery);
//
//   @override
//   Future<ChatAttachment?> captureFromCamera() => _pick(ImageSource.camera);
//
//   Future<ChatAttachment?> _pick(ImageSource source) async {
//     final file = await _picker.pickImage(source: source, imageQuality: 85);
//     if (file == null) return null;
//     final decoded = await decodeImageFromList(await file.readAsBytes());
//     return ChatAttachment(
//       url: file.path,
//       mimeType: 'image/jpeg',
//       width: decoded.width,
//       height: decoded.height,
//     );
//   }
// }

import '../../models/chat/chat_attachment.dart';

/// Contract for picking or capturing an image and returning it as a
/// [ChatAttachment] ready for [ChatThreadController.sendAttachment].
abstract class ImageAttachmentPicker {
  Future<ChatAttachment?> pickFromGallery();
  Future<ChatAttachment?> captureFromCamera();
}

/// No-native-plugin stub that returns a sample remote image so the feature
/// compiles and renders without requiring device permissions. Replace with a
/// real [ImageAttachmentPicker] implementation before shipping.
class StubImageAttachmentPicker implements ImageAttachmentPicker {
  const StubImageAttachmentPicker();

  @override
  Future<ChatAttachment?> pickFromGallery() async => const ChatAttachment(
        url: 'https://picsum.photos/seed/hub-gallery/800/600',
        mimeType: 'image/jpeg',
        width: 800,
        height: 600,
      );

  @override
  Future<ChatAttachment?> captureFromCamera() async => const ChatAttachment(
        url: 'https://picsum.photos/seed/hub-camera/600/800',
        mimeType: 'image/jpeg',
        width: 600,
        height: 800,
      );
}
