/// Central dependency injection — Riverpod providers for all features.

library;



import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



export '../../features/auth/presentation/providers/auth_providers.dart';

export '../../features/chat/presentation/providers/chat_providers.dart';

export '../../features/notifications/presentation/providers/notification_providers.dart';

export '../../features/payment/presentation/providers/payment_providers.dart';

export '../../features/profile/presentation/providers/profile_providers.dart';

export '../../features/request/presentation/providers/request_providers.dart';

export '../../features/rewards/presentation/providers/rewards_providers.dart';

export '../../features/tracking/presentation/providers/tracking_providers.dart';

export '../../features/wallet/presentation/providers/wallet_providers.dart';



final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {

  return FirebaseAuth.instance;

});



final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {

  return FirebaseFirestore.instance;

});



final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {

  return FirebaseStorage.instance;

});



final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {

  return FirebaseMessaging.instance;

});



/// Global navigator key for FCM deep-link routing.

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {

  return GlobalKey<NavigatorState>();

});


