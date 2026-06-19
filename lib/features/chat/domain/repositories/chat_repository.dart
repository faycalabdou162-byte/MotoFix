import '../../../../models/feature_models.dart';

abstract class ChatRepository {
  Stream<List<ChatMessageModel>> watchMessages(String requestId);

  Future<void> sendText({required String requestId, required String text});

  Future<void> sendCurrentLocation(String requestId);

  Future<void> sendPhotoReference({
    required String requestId,
    required String photoUrl,
    String caption,
  });

  Future<void> sendVoiceReference({
    required String requestId,
    required String voiceUrl,
    String label,
  });

  /// Uploads image bytes to Storage — returns public download URL.
  Future<String> uploadChatImage({
    required String requestId,
    required List<int> bytes,
    required String fileName,
  });
}
