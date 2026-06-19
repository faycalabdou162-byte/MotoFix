import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../features/chat/data/datasources/chat_firebase_datasource.dart';
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';

export '../features/chat/domain/repositories/chat_repository.dart'
    show ChatRepository;

/// Backward-compatible facade — prefer [chatRepositoryProvider].
class ChatService extends ChatRepositoryImpl {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : super(
          dataSource: ChatFirebaseDataSource(
            firestore: firestore,
            auth: auth,
            storage: storage,
          ),
        );
}
