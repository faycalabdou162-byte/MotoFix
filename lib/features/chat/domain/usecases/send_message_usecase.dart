import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> sendText({required String requestId, required String text}) {
    return _repository.sendText(requestId: requestId, text: text);
  }

  Future<void> sendLocation(String requestId) {
    return _repository.sendCurrentLocation(requestId);
  }

  Future<void> sendPhoto({
    required String requestId,
    required String photoUrl,
    String caption = '',
  }) {
    return _repository.sendPhotoReference(
      requestId: requestId,
      photoUrl: photoUrl,
      caption: caption,
    );
  }
}
