import '../../../../models/feature_models.dart';
import '../repositories/chat_repository.dart';

class ListenMessagesUseCase {
  const ListenMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Stream<List<ChatMessageModel>> call(String requestId) {
    return _repository.watchMessages(requestId);
  }
}
