import '../../../../models/feature_models.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_firebase_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({ChatFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? ChatFirebaseDataSource();

  final ChatFirebaseDataSource _dataSource;

  @override
  Stream<List<ChatMessageModel>> watchMessages(String requestId) {
    return _dataSource.watchMessages(requestId);
  }

  @override
  Future<void> sendText({
    required String requestId,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _dataSource.sendMessage(
      requestId: requestId,
      type: ChatMessageType.text,
      text: clean,
    );
  }

  @override
  Future<void> sendCurrentLocation(String requestId) async {
    final location = await _dataSource.currentLocation();
    await _dataSource.sendMessage(
      requestId: requestId,
      type: ChatMessageType.location,
      text: 'Position partagee',
      location: location,
    );
  }

  @override
  Future<void> sendPhotoReference({
    required String requestId,
    required String photoUrl,
    String caption = '',
  }) {
    return _dataSource.sendMessage(
      requestId: requestId,
      type: ChatMessageType.photo,
      text: caption.trim().isEmpty ? 'Photo de panne' : caption.trim(),
      photoUrl: photoUrl.trim(),
    );
  }

  @override
  Future<void> sendVoiceReference({
    required String requestId,
    required String voiceUrl,
    String label = 'Message vocal',
  }) {
    return _dataSource.sendMessage(
      requestId: requestId,
      type: ChatMessageType.voice,
      text: label.trim().isEmpty ? 'Message vocal' : label.trim(),
      voiceUrl: voiceUrl.trim(),
    );
  }

  @override
  Future<String> uploadChatImage({
    required String requestId,
    required List<int> bytes,
    required String fileName,
  }) {
    return _dataSource.uploadImage(
      requestId: requestId,
      bytes: bytes,
      fileName: fileName,
    );
  }
}
