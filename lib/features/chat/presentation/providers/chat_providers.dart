import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../models/feature_models.dart';
import '../../data/datasources/chat_firebase_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/listen_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    dataSource: ChatFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
      auth: ref.watch(firebaseAuthProvider),
    ),
  );
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final listenMessagesUseCaseProvider = Provider<ListenMessagesUseCase>((ref) {
  return ListenMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, requestId) {
  return ref.watch(listenMessagesUseCaseProvider).call(requestId);
});
